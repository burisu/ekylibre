module Ekylibre
  module Record
    module HasShape #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      class << self
        def clean_for_active_record(value, options = {})
          return nil if value.to_s =~ /\A[[:space:]]*\z/
          return value if value.is_a? RGeo::Feature::Instance

          value = if value.is_a?(Hash) || (value.is_a?(String) && value =~ /\A\{.*\}\z/)
                    begin
                      Geo.from_geojson(value)
                    rescue => e
                      fixed_geojson = correct_geojson(value, options[:type])
                      value = fixed_geojson.get if fixed_geojson.is_some?
                    end
                  else
                    Geo.new_geometry(value)
                  end

          fixed_value = correct_shape(value, options[:type])
          value = fixed_value.get if fixed_value.is_some?

          if value.type == :geometry_collection
            extracted_shape = extract_geometries(value, options[:type])
            value = extracted_shape.get if extracted_shape.is_some?
          end

          if options[:type] && options[:type] == :multi_polygon
            value = value.convert_to(:multi_polygon)
          elsif options[:type] && options[:type] == :point
            value = value.convert_to(:point)
          end
          value.to_rgeo
        end

        def correct_geojson(value, type)
          geojson = Geo::GeoJSON.new(value, "4326")
          correct_shape(geojson, type)
        end

        def correct_shape(shape, type)
          corrector = ShapeCorrector.build
          corrector.try_fix(shape, geometry_type: type)
        end

        def extract_geometries(shape, type)
          corrector = ShapeCorrector.build
          corrector.extract_geometries(shape, type)
        end
      end

      module ClassMethods
        SRID = {
          wgs84: 4326,
          rgf93: 2154
        }.freeze

        # BUG: does not handle polygons with holes in them. If you need the centroid, use `geom_union_centroid` that let Postgis do everything
        def geom_union(column_name)
          plucked_ids = pluck(:id).join(',')

          if plucked_ids.blank?
            Geo.empty_geometry
          else
            conn = connection
            Geo.new_geometry(conn.select_value('SELECT ST_MakeValid(ST_AsEWKT(ST_Union(' + conn.quote_column_name(column_name) + '))) FROM ' + conn.quote_table_name(table_name) + ' WHERE id in (' + plucked_ids + ')'))
          end
        end

        # More robust implementation of geom_union(:column_name).centroid that does everything in Postgis and handles weird geometries that RGeo does not.
        def geom_union_centroid(column_name)
          plucked_ids = pluck(:id).join(',')

          if plucked_ids.blank?
            Geo.empty_geometry
          else
            conn = connection
            Geo.new_geometry(conn.select_value('SELECT ST_AsEWKT(ST_Centroid(ST_Union(' + conn.quote_column_name(column_name) + '))) FROM ' + conn.quote_table_name(table_name) + ' WHERE id in (' + plucked_ids + ')')).feature
          end
        end

        # More robust implementation of to_svg from Geo for multiple objects
        def compute_svg(column_name, options = {})
          plucked_ids = pluck(:id).join(',')

          options[:color] ||= 'black'
          options[:stroke_width] ||= 1
          options[:height] ||= 180
          options[:width] ||= 180

          if plucked_ids.blank?
            nil
          else
            svg = ActiveRecord::Base.connection.execute <<~SQL
              WITH
                query AS (SELECT #{column_name} AS geometry FROM #{table_name} WHERE id IN (#{plucked_ids}) ),
                q AS (SELECT
                    ST_XMin(ST_Collect(geometry)) as x_min,
                    ST_XMax(ST_Collect(geometry)) as x_max,
                    ST_YMin(ST_Collect(geometry)) as y_min,
                    ST_YMax(ST_Collect(geometry)) as y_max,
                    ARRAY_TO_STRING(ARRAY_AGG(CONCAT('<path d="', ST_AsSVG(geometry), '" ', 'fill="none" ', 'stroke="#{options[:color]}" ', 'stroke-linecap="butt" ', 'stroke-linejoin="round" ', 'stroke-width="#{options[:stroke_width].to_s}%"', ' />')),'') as svg FROM query )
              SELECT
                CONCAT('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="#{options[:height].to_s}" width="#{options[:width].to_s}" viewBox="',
                    CONCAT_WS(' ', q.x_min, -1 * q.y_max, q.x_max-q.x_min, q.y_max-q.y_min), '">', q.svg, '</svg>') FROM q;
            SQL
            svg.first["concat"].gsub(/\"/, '\'')
          end
        end

        def perimeters(column_name, options = {})
          plucked_ids = pluck(:id).join(',')
          if plucked_ids.blank?
            nil
          else
            per = ActiveRecord::Base.connection.execute <<~SQL
              SELECT SUM(ST_Perimeter(#{column_name}::geography)) AS sum_perimeter FROM #{table_name} WHERE id IN (#{plucked_ids});
            SQL
            perimeter = per.first["sum_perimeter"]
            perimeter.round(2).in_meter
          end
        end

        def has_geometry(*columns)
          options = columns.extract_options!
          options[:type] ||= :multi_polygon
          columns.each do |column|
            col = column.to_s
            define_method "#{col}=" do |value|
              self[col] = Ekylibre::Record::HasShape.clean_for_active_record(value, options)
            end

            define_method col do
              self[col].blank? ? nil : Geo.new_geometry(self[col])
            end

            unless %i[point multi_point line_string multi_line_string].include?(options[:type])
              define_method "#{col}_area" do |unit = nil|
                return 0.in(unit || :square_meter) if send(col).nil?

                if unit
                  send(col).area.in(:square_meter).in(unit)
                else
                  send(col).area.in(:square_meter)
                end
              end

              define_method "human_#{col}_area" do |mode = :metric|
                area = (send(col) ? send(col + '_area') : 0.in_square_meter)
                if mode == :imperial
                  area.in(:acre).round(3).l
                else # metric
                  area.in_hectare.round(3).l
                end
              end
            end

            define_method "#{col}_centroid" do |_unit = nil|
              send(col)&.centroid
            end

            scope col + '_overlapping', lambda { |shape|
              where('ST_Overlaps(' + col + ', ST_GeomFromEWKT(?))', ::Geo.new_geometry(shape).to_ewkt)
            }

            scope col + '_covering', lambda { |shape, margin = 0|
              ewkt = ::Geo.new_geometry(shape).to_ewkt
              if margin > 0
                common = 1 - margin
                where('(ST_Overlaps(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?))) AND ST_Area(ST_Intersection(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))) / ST_Area(ST_GeomFromEWKT(ST_MakeValid(?))) >= ?)', ewkt, ewkt, ewkt, common)
              else
                where('ST_Covers(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ewkt)
              end
            }

            scope col + '_intersecting', lambda { |shape|
              where('ST_Intersects(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ::Geo.new_geometry(shape).to_ewkt)
            }

            scope col + '_surface_intersecting', lambda { |shape|
              where('ST_Intersects(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?))) AND ST_Area(ST_Intersection(ST_MakeValid(' + col + '), ST_GeomFromEWKT(ST_MakeValid(?)))) > ?', ::Geo.new_geometry(shape).to_ewkt, ::Geo.new_geometry(shape).to_ewkt, 1E-10)
            }

            scope col + '_covered_by', lambda { |shape|
              where('ST_CoveredBy(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ::Geo.new_geometry(shape).to_ewkt)
            }

            scope col + '_within', lambda { |shape|
              where('ST_Within(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ::Geo.new_geometry(shape).to_ewkt)
            }

            scope col + '_matching', lambda { |shape, margin = 0.05|
              ewkt = ::Geo.new_geometry(shape).to_ewkt
              common = 1 - margin
              where('ST_Equals(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?))) OR (ST_Overlaps(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?))) AND ST_Area(ST_Intersection(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))) / ST_Area(' + col + ') >= ? AND ST_Area(ST_Intersection(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))) / ST_Area(ST_GeomFromEWKT(ST_MakeValid(?))) >= ?)', ewkt, ewkt, ewkt, common, ewkt, ewkt, common)
            }

            scope col + '_near', lambda { |shape, max_distance_in_meter = 5000|
              c = ::Geo.new_geometry(shape).buffer(max_distance_in_meter)
              ewkt = ::Geo.new_geometry(c).to_ewkt
              where('ST_Intersects(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ewkt)
            }

            scope col + '_nearest_of_and_within', lambda { |shape, max_distance_in_meter = 5000|
              c = ::Geo.new_geometry(shape).buffer(max_distance_in_meter)
              ewkt = ::Geo.new_geometry(c).to_ewkt
              where( col + ' IN (?)', select(col)
                                      .where('ST_Intersects(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ewkt)
                                      .order(Arel.sql('ST_Distance(' + col + ', ST_Centroid(' + connection.quote(ewkt) + ')) ASC'))
                                      .limit(1))
            }

            scope :without_intersected_with_selection, ->(*selected_ids){
              joins(<<~SQL).where('selecteds.id IS NULL')
                LEFT JOIN (#{self.where(id: selected_ids).to_sql}) AS selecteds
                ON (ST_INTERSECTS(#{self.table_name}.#{col}, selecteds.#{col})
                  AND NOT ST_TOUCHES(#{self.table_name}.#{col}, selecteds.#{col}))
                  AND #{self.table_name}.id != selecteds.id
              SQL
            }

            scope :in_bounding_box, ->(bounding_box){
              where("#{self.table_name}.#{col} && ST_MakeEnvelope(#{bounding_box})")
            }

            scope 'without_intersected_with_' + col, ->(shape){
              joins(<<~SQL).where('table_2.intersect_with_shape = FALSE')
                LEFT JOIN (SELECT (ST_INTERSECTS(#{self.table_name}.#{col}, '#{shape}')
                                  AND NOT ST_TOUCHES(#{self.table_name}.#{col}, '#{shape}')) AS intersect_with_shape,
                                  id
                          FROM #{self.table_name}) as table_2
                          ON #{self.table_name}.id = table_2.id
              SQL
            }
          end
        end

        # Returns the corresponding SRID from its name or number
        def srid(srname)
          return srname if srname.is_a?(Integer)
          unless id = SRID[srname]
            raise ArgumentError.new("Unreferenced SRID: #{srname.inspect}")
          end

          id
        end

        # Defines geometric methods on the shape indicators (stored in product readings)
        def has_shape(*indicators)
          indicators.pop if indicators.last.is_a?(Hash)
          indicators = [:shape] if indicators.empty?
          column = :geometry_value

          indicators.each do |indicator|
            define_singleton_method("#{indicator}_view_box") do |options = {}|
              expr = options[:srid] ? "ST_Transform(#{column}, #{srid(options[:srid])})" : column.to_s
              ids = ProductReading.of_products(self, indicator, options[:at]).pluck(:id)
              return [] unless ids.any?

              values = connection.select_one(
                "SELECT min(ST_XMin(#{expr})) AS x_min, min(ST_YMin(#{expr})) AS y_min, max(ST_XMax(#{expr})) AS x_max, max(ST_YMax(#{expr})) AS y_max " \
                "FROM #{ProductReading.indicator_table_name(indicator)} WHERE id IN (#{ids.map(&:to_i).join(',')})"
              ).symbolize_keys
              [values[:x_min].to_f, -values[:y_max].to_f, (values[:x_max].to_f - values[:x_min].to_f), (values[:y_max].to_f - values[:y_min].to_f)]
            end

            # As SVG
            define_singleton_method("#{indicator}_svg") do |options = {}|
              ids = ProductReading.of_products(self, indicator, options[:at]).pluck(:product_id)
              svg = +'<svg xmlns="http://www.w3.org/2000/svg" version="1.1"'
              return (svg + '/>').html_safe unless ids.any?

              svg << %( class="#{indicator}" preserveAspectRatio="xMidYMid meet" width="100%" height="100%" viewBox="#{public_send("#{indicator}_view_box", options).join(' ')}">)
              Product.where(id: ids).each do |product|
                svg << %(<path d="#{product.public_send("#{indicator}_to_svg_path", options)}"/>)
              end
              svg << '</svg>'
              svg.html_safe
            end

            # Return SVG as String
            define_method("#{indicator}_svg") do |options = {}|
              options[:srid] ||= 2154
              return nil unless reading(indicator, at: options[:at])

              geom = Geo.new_geometry(public_send(indicator))
              geom = geom.transform(options[:srid]) if options[:srid]
              geom.to_svg(options)
            end

            # Return ViewBox
            define_method("#{indicator}_view_box") do |options = {}|
              return nil unless reading(indicator, at: options[:at])

              [public_send("#{indicator}_x_min", options), -public_send("#{indicator}_y_max", options),
               public_send("#{indicator}_width", options), public_send("#{indicator}_height", options)]
            end

            %i[x_min x_max y_min y_max to_svg to_svg_path to_gml to_kml to_geojson to_text to_binary to_ewkt centroid point_on_surface].each do |attr|
              define_method("#{indicator}_#{attr.to_s.downcase}") do |options = {}|
                return nil unless (reading = reading(indicator, at: options[:at]))

                geometry = Geo.new_geometry(reading.public_send(column))
                geometry = geometry.transform(options[:srid]) if options[:srid]
                geometry.public_send(attr)
              end
            end

            define_method("#{indicator}_area") do |options = {}|
              return nil unless (reading = reading(indicator, at: options[:at]))

              geometry = Geo.new_geometry(reading.public_send(column))
              geometry = geometry.transform(options[:srid]) if options[:srid]
              geometry.area.in_square_meter
            end

            define_method("#{indicator}_width") do |options = {}|
              public_send("#{indicator}_x_max", options) - public_send("#{indicator}_x_min", options)
            end

            define_method("#{indicator}_height") do |options = {}|
              public_send("#{indicator}_y_max", options) - public_send("#{indicator}_y_min", options)
            end
          end
        end
      end
    end
  end
end
