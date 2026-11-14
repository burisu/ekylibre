# frozen_string_literal: true

module Geo
  # Geometry with SRID wrapping an RGeo feature
  class Geometry
    def initialize(feature, properties = {})
      self.feature = feature
      @properties = properties
    end

    def inspect
      "<#{self.class.name}(#{to_ewkt})>"
    end

    # Type of the geometry as a symbol: :point, :multi_polygon...
    def type
      Geo.underscore(feature.geometry_type.type_name).to_sym
    end

    def collection?
      feature.geometry_type == RGeo::Feature::GeometryCollection
    end

    def srid
      feature.srid.to_i
    end

    # WKT without SRID
    def to_text
      text = feature.as_text
      text =~ /\ASRID=.*;(.*)/ ? Regexp.last_match(1) : text
    end
    alias as_text to_text
    alias to_wkt to_text

    # WKT with SRID
    def to_ewkt
      Geo.generate_ewkt(feature).to_s
    end
    alias to_s to_ewkt

    def to_binary
      RGeo::WKRep::WKBGenerator.new(tag_format: :ewkbt, emit_ewkbt_srid: true).generate(feature)
    end
    alias to_ewkb to_binary

    # SVG image of the geometry
    # Options: :mode (:stroke or :fill), :color, :fill_opacity, :stroke_linecap,
    # :stroke_linejoin, :stroke_width
    def to_svg(options = {})
      options = { mode: :stroke, color: 'black', fill_opacity: '100', stroke_linecap: 'butt', stroke_linejoin: 'round', stroke_width: '5%' }.merge(options)
      path = if options[:mode] == :fill
               { d: to_svg_path, fill: options[:color], 'fill-opacity': options[:fill_opacity] }
             else
               { d: to_svg_path, fill: 'none', stroke: options[:color], 'stroke-linecap': options[:stroke_linecap],
                 'stroke-linejoin': options[:stroke_linejoin], 'stroke-width': options[:stroke_width] }
             end
      SVG.document(path, width: 180, height: 180, viewBox: bounding_box.svg_view_box.join(' '))
    end

    def to_svg_path
      SVG.encode(feature)
    end

    def to_geojson
      to_json_object.to_json
    end
    alias to_json to_geojson

    def to_json_object(*)
      RGeo::GeoJSON.encode(feature)
    end

    def to_json_feature(properties = {})
      { type: 'Feature', properties: properties, geometry: to_json_object }
    end

    def ==(other)
      other_geometry = Geo.new_geometry(other).transform(srid)
      return true if empty? && other_geometry.empty?
      return inspect == other_geometry.inspect if collection? && other_geometry.collection?

      feature.equals?(other_geometry.feature)
    end

    def !=(other)
      !(self == other)
    end

    def surface?
      if collection?
        feature.any? { |geometry| Geo.new_geometry(geometry).surface? }
      else
        [RGeo::Feature::Polygon, RGeo::Feature::MultiPolygon].include?(feature.geometry_type)
      end
    end

    # Area in unit of the SRS (m² for WGS84)
    def area
      return 0 unless surface?

      collection? ? feature.sum { |geometry| Geo.new_geometry(geometry).area } : feature.area
    end

    def empty?
      feature.empty?
    end
    alias blank? empty?

    # Center of mass as [latitude, longitude]
    def centroid
      return nil unless surface? && !feature.empty?

      point = feature.centroid
      [point.y, point.x]
    end

    # Point lying on the surface as [latitude, longitude]
    def point_on_surface
      return nil unless surface?

      point = feature.point_on_surface
      [point.y, point.x]
    end

    def convert_to(new_type)
      case new_type
      when type then self
      when :multi_point then flatten_multi(:point)
      when :multi_line_string then flatten_multi(:line_string)
      when :multi_polygon then flatten_multi(:polygon)
      else self
      end
    end

    def flatten_multi(as_type)
      items = []
      as_multi_type = "multi_#{as_type}".to_sym
      if type == as_type
        items << feature
      elsif type == :geometry_collection
        feature.each do |geom|
          type_name = Geo.underscore(geom.geometry_type.type_name).to_sym
          if type_name == as_type
            items << geom
          elsif type_name == as_multi_type
            geom.each { |item| items << item }
          end
        end
      end
      Geo.new_geometry(feature.factory.send(as_multi_type, items))
    end

    # Returns a new geometry with the coordinates converted into the new SRS
    def transform(new_srid)
      new_srid = Geo::SRS[new_srid] || new_srid
      return self if new_srid.to_i == srid

      new_feature = RGeo::CoordSys::Proj4.transform(Geo.proj(srid), feature, Geo.proj(new_srid), Geo.factory(new_srid))
      Geo.new_geometry(Geo.generate_ewkt(new_feature))
    end

    # Simpler geometry computed by PostGIS (ST_SimplifyPreserveTopology)
    # @param [Float] tolerance
    def simplify(tolerance)
      Geo.new_geometry(Geo.postgis_value('ST_AsText(ST_SimplifyPreserveTopology(ST_GeomFromText(:feature), :tolerance))', feature: feature.as_text, tolerance: tolerance))
    end

    # Buffer of +radius+ meters computed by PostGIS on geography
    def buffer(radius)
      Geo.new_geometry(Geo.postgis_value('ST_AsText(ST_Buffer(ST_GeomFromText(:feature)::geography, :radius))', feature: feature.as_text, radius: radius.to_f))
    end

    def merge(other)
      feature.union(Geo.new_geometry(other).transform(srid).feature)
    end
    alias + merge

    def intersection(other)
      feature.intersection(Geo.new_geometry(other).transform(srid).feature)
    end

    def intersects?(other)
      feature.intersects?(Geo.new_geometry(other).transform(srid).feature)
    end

    def difference(other)
      feature.difference(Geo.new_geometry(other).transform(srid).feature)
    end
    alias - difference

    def bounding_box
      @bounding_box ||= begin
        bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(feature)
        BoundingBox.new(bbox.min_y || 0, bbox.min_x || 0, bbox.max_y || 0, bbox.max_x || 0)
      end
    end

    %i[x_min y_min x_max y_max].each do |name|
      define_method(name) { bounding_box.send(name) }
    end

    def find_srid(name_or_srid)
      Geo.find_srid(name_or_srid)
    end

    # Underlying RGeo feature
    def feature
      @feature.dup
    end
    alias to_rgeo feature

    def feature=(new_feature)
      raise ArgumentError.new("Feature can't be nil") if new_feature.nil?

      @feature = new_feature
    end

    def method_missing(name, *args, &block)
      target = to_rgeo
      return target.send(name, *args, &block) if target.respond_to?(name)

      super
    end

    def respond_to_missing?(name, include_private = false)
      return false if name == :init_with

      super
    end
  end

  class Point < Geometry
    def x
      feature.x
    end
    alias longitude x

    def y
      feature.y
    end
    alias latitude y

    def distance(point)
      raise ArgumentError.new('wrong type: Geo::Point required') unless point.is_a?(Geo::Point)

      to_rgeo.distance(point.to_rgeo)
    end
  end

  class LineString < Geometry
    def each_point(&block)
      raise 'Cannot browse each point without parameter' unless [1, 2].include?(block.arity)

      block.arity == 1 ? points.each(&block) : points.each_with_index(&block)
    end

    def points
      @points ||= feature.points.map { |point| Point.new(point) }
    end
  end

  class Polygon < Geometry
    def exterior_ring
      @exterior_ring ||= Geo.new_geometry(Geo.generate_ewkt(feature.exterior_ring))
    end

    def distance(point)
      Geo.new_point(*centroid, 4326).distance(point)
    end

    # Polygon made of the exterior ring only (computed by PostGIS)
    def without_hole_outside_shell
      Geo.new_geometry(Geo.postgis_value('ST_AsText(ST_MakePolygon(ST_ExteriorRing(:feature)))', feature: feature.as_text))
    end

    def hole_outside_shell?
      Geo.postgis_value('ST_IsValidReason(:feature)', feature: feature.as_text).to_s.start_with?('Hole lies outside shell')
    end
  end

  class GeometryCollection < Geometry
    def self.empty(srid = nil)
      new(Geo.empty_feature(srid.nil? ? :WGS84 : srid))
    end

    def to_json_feature_collection(collection_properties = [])
      features = feature.each.with_index.collect do |f, i|
        Geo.new_geometry(f).to_json_feature(collection_properties[i] || {})
      end
      { type: 'FeatureCollection', features: features }
    end
  end

  class MultiPolygon < GeometryCollection
    def each_polygon(&block)
      raise 'Cannot browse each polygon without parameter' unless [1, 2].include?(block.arity)

      if block.arity == 1
        polygons.each(&block)
      else
        polygons.each_with_index { |polygon, index| yield polygon, index + 1 }
      end
    end

    def polygons
      @polygons ||= feature.elements.map { |polygon| Polygon.new(polygon) }
    end
  end
end
