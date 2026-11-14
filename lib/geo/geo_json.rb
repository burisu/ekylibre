# frozen_string_literal: true

module Geo
  # GeoJSON to EWKT conversion
  class GeoJSON
    attr_reader :srid

    def initialize(data, srid = :WGS84)
      srid ||= :WGS84
      @json = self.class.flatten(data.is_a?(Hash) ? data.deep_stringify_keys : JSON.parse(data))
      crs = @json['crs'] if @json.is_a?(Hash)
      lsrid = crs['properties']['name'] if crs.is_a?(Hash) && crs['properties'].is_a?(Hash)
      @srid = Geo.find_srid(lsrid || srid)
      @json = self.class.normalize_4326(@json) if @srid.to_i == 4326
    end

    def geom
      Geo.new_geometry(to_ewkt)
    end

    def to_hash
      @json
    end

    def to_ewkt
      "SRID=#{srid};" + self.class.object_to_ewkt(@json)
    end

    def valid?
      to_ewkt
      true
    rescue StandardError
      false
    end

    class << self
      def valid?(data, srid = :WGS84)
        new(data, srid).valid?
      rescue StandardError
        false
      end

      # Forces coordinates to 2D
      def flatten(hash)
        map_coordinates(hash) { |position| position[0..1] }
      end

      def normalize_4326(json)
        map_coordinates(json) do |(x, y)|
          [((x + 180.to_d) % 360.to_d) - 180.to_d, ((y + 90.to_d) % 180.to_d) - 90.to_d]
        end
      end

      def object_to_ewkt(hash)
        type = hash[:type] || hash['type']
        case type
        when 'FeatureCollection'
          collection_to_ewkt(hash['features'])
        when 'GeometryCollection'
          collection_to_ewkt(hash['geometries'])
        when 'Feature'
          object_to_ewkt(hash['geometry'])
        when 'Point'
          hash['coordinates'].nil? ? 'POINT EMPTY' : "POINT(#{hash['coordinates'].join(' ')})"
        when 'LineString'
          wkt('LINESTRING', hash['coordinates']) { |c| "(#{points(c)})" }
        when 'Polygon'
          wkt('POLYGON', hash['coordinates']) { |c| "(#{rings(c)})" }
        when 'MultiPoint'
          wkt('MULTIPOINT', hash['coordinates']) { |c| '(' + c.map { |p| "(#{p.join(' ')})" }.join(', ') + ')' }
        when 'MultiLineString'
          wkt('MULTILINESTRING', hash['coordinates']) { |c| "(#{rings(c)})" }
        when 'MultiPolygon', 'Multipolygon'
          wkt('MULTIPOLYGON', hash['coordinates']) { |c| '(' + c.map { |polygon| "(#{rings(polygon)})" }.join(', ') + ')' }
        else
          raise ArgumentError.new("Cannot handle GeoJSON type: #{type.inspect}")
        end
      end

      private

        def wkt(name, coordinates)
          coordinates.nil? ? "#{name} EMPTY" : name + yield(coordinates)
        end

        def points(line)
          line.map { |point| point.join(' ') }.join(', ')
        end

        def rings(lines)
          lines.map { |line| "(#{points(line)})" }.join(', ')
        end

        def collection_to_ewkt(items)
          return 'GEOMETRYCOLLECTION EMPTY' if items.nil?

          'GEOMETRYCOLLECTION(' + items.map { |item| object_to_ewkt(item) }.join(', ') + ')'
        end

        def map_coordinates(hash, &block)
          case hash['type']
          when 'FeatureCollection'
            hash.merge('features' => hash['features'].map { |feature| map_feature(feature, &block) })
          when 'Feature'
            map_feature(hash, &block)
          else
            map_geometry(hash, &block)
          end
        end

        def map_feature(hash, &block)
          hash.merge('geometry' => map_geometry(hash['geometry'], &block))
        end

        def map_geometry(hash, &block)
          if hash['type'] == 'GeometryCollection'
            return hash.merge('geometries' => hash['geometries'].map { |geometry| map_geometry(geometry, &block) })
          end

          coordinates = hash['coordinates']
          mapped = case hash['type']
                   when 'Point' then block.call(coordinates)
                   when 'MultiPoint', 'LineString' then coordinates.map(&block)
                   when 'MultiLineString', 'Polygon' then coordinates.map { |line| line.map(&block) }
                   when 'MultiPolygon' then coordinates.map { |poly| poly.map { |line| line.map(&block) } }
                   else raise ArgumentError.new("Cannot handle: #{hash['type'].inspect}. In #{hash.inspect}")
                   end
          hash.merge('coordinates' => mapped)
        end
    end
  end
end
