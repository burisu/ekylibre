# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'
require 'json'
require 'rgeo'
require 'rgeo/geo_json'
require 'rgeo/proj4'

# Geometry toolbox built directly on RGeo.
#
# Replaces the former ekylibre/charta gem (MIT, Copyright (c) 2017 Brice
# Texier) with the subset of its API used by Ekylibre: geometries are RGeo
# features (projected geographic factory for WGS84 so areas are in m²) wrapped
# in Geo::Geometry objects.
module Geo
  SRS = {
    WGS84: 4326,
    CRS84: 4326,
    RGF93: 2143
  }.freeze


  class << self
    # Callable receiving (ewkt, error) when an EWKT cannot be parsed into a
    # valid geometry. Must return a fixed EWKT or nil (see ShapeCorrector).
    attr_accessor :invalid_geometry_handler

    # @return [Geo::Geometry]
    def new_geometry(coordinates, srs = nil, format = nil, _flatten_collection = true, _options = {})
      return coordinates if coordinates.is_a?(Geometry)

      wrap(new_feature(coordinates, srs, format))
    end

    # @return [RGeo::Feature::Instance]
    def new_feature(coordinates, srs = nil, format = nil)
      case coordinates
      when Geometry
        coordinates.feature
      when RGeo::Feature::Instance
        cast(coordinates)
      else
        if coordinates.to_s =~ /\A[[:space:]]*\z/
          empty_feature(srs || :WGS84)
        else
          srid = srs.nil? ? nil : find_srid(srs)
          feature_from_ewkt(to_ewkt(coordinates, srid: srid, format: format))
        end
      end
    end

    def new_point(lat, lon, srid = 4326)
      new_geometry("SRID=#{srid};POINT(#{lon} #{lat})")
    end

    # coordinates is an array of x,y
    def make_polygon(coordinates, options = {})
      srid = options[:srid] || 4326
      points = coordinates.map { |x, y| options[:swap] ? "#{y} #{x}" : "#{x} #{y}" }
      new_geometry("SRID=#{srid};POLYGON((#{points.join(', ')}))")
    end

    def make_line(points, options = {})
      srid = options[:srid]
      srid ||= new_geometry(points.first).srid if points.any?
      srid ||= 4326
      coordinates = points.map do |wkt|
        point = new_geometry(wkt)
        "#{point.x} #{point.y}"
      end
      new_geometry("SRID=#{srid};LINESTRING(#{coordinates.join(', ')})")
    end

    def empty_geometry(srs = :WGS84)
      wrap(empty_feature(srs))
    end

    def empty_feature(srs = :WGS84)
      feature_from_ewkt("SRID=#{find_srid(srs || :WGS84)};GEOMETRYCOLLECTION EMPTY")
    end

    def from(format, data)
      raise ArgumentError.new("Unknown format: #{format.inspect}") unless %w[gml kml geojson].include?(format.to_s)

      public_send("from_#{format}", data)
    end

    def from_gml(data, srid = nil, _flatten_collection = false)
      new_geometry(GML.new(data, srid).to_ewkt)
    end

    def from_kml(data, _flatten_collection = false)
      new_geometry(KML.new(data).to_ewkt)
    end

    def from_geojson(data, srid = nil)
      new_geometry(GeoJSON.new(data, srid).to_ewkt)
    end

    def generate_ewkt(feature)
      RGeo::WKRep::WKTGenerator.new(tag_format: :ewkt, emit_ewkt_srid: true).generate(feature)
    end

    # Returns the SRID matching with an SRS name, URN, EPSG code or SRID
    def find_srid(srname_or_srid)
      value = srname_or_srid.to_s
      if value =~ /\Aurn:ogc:def:crs:.*\z/
        key = value.split(':').last.upcase.to_sym
        SRS[key] || key
      elsif value =~ /\AEPSG::?(\d{4,5})\z/
        value.split(':').last
      elsif value =~ /\A\d+\z/
        value.to_i
      else
        SRS[srname_or_srid.is_a?(String) ? srname_or_srid.to_sym : srname_or_srid] || srname_or_srid
      end
    end

    # Wraps an RGeo feature in the matching Geo::Geometry subclass
    def wrap(feature)
      klass = case feature.geometry_type
              when RGeo::Feature::Point then Point
              when RGeo::Feature::LineString then LineString
              when RGeo::Feature::Polygon then Polygon
              when RGeo::Feature::MultiPolygon then MultiPolygon
              when RGeo::Feature::GeometryCollection then GeometryCollection
              else Geometry
              end
      klass.new(feature)
    end

    # Casts an RGeo feature to the factory of its SRID
    def cast(feature)
      RGeo::Feature.cast(feature, factory: factory(feature.srid))
    end

    # Parses EWKT, delegating invalid geometries to invalid_geometry_handler
    def feature_from_ewkt(ewkt)
      raise ArgumentError.new("Invalid data: #{ewkt.inspect}") if ewkt.to_s =~ /\A[[:space:]]*\z/

      parse_ewkt(ewkt)
    rescue RGeo::Error::InvalidGeometry => e
      fixed = invalid_geometry_handler&.call(ewkt, e)
      raise e if fixed.nil?

      parse_ewkt(fixed)
    end

    def parse_ewkt(ewkt)
      # Cleans empty geometries
      ewkt = ewkt.gsub(/(GEOMETRYCOLLECTION|GEOMETRY|((MULTI)?(POINT|LINESTRING|POLYGON)))\(\)/, '\1 EMPTY')
      srs = ewkt.split(/[=;]+/)[0..1]
      srid = srs[0] =~ /srid/i ? srs[1] : 4326
      factory(srid).parse_wkt(ewkt)
    rescue RGeo::Error::ParseError => e
      raise ArgumentError.new("Invalid EWKT (#{e.class.name}: #{e.message}): #{ewkt}")
    end

    def factory(srid = 4326)
      srid = srid.to_i
      @factories ||= {}
      @factories[srid] ||= srid == 4326 ? projected_factory(srid) : geos_factory(srid)
    end

    def srs_database
      @srs_database ||= RGeo::CoordSys::SRSDatabase::Proj4Data.new('epsg', authority: 'EPSG', cache: true)
    end

    # Evaluates a PostGIS expression with named binds and returns the value
    def postgis_value(expression, binds = {})
      sql = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT #{expression}", binds])
      ActiveRecord::Base.connection.select_value(sql)
    end

    def underscore(text)
      text.gsub(/::/, '/')
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr('-', '_')
          .downcase
    end

    private

      # Converts supported inputs (GeoJSON, WKB, GML, KML, EWKT) to EWKT
      def to_ewkt(value, srid: nil, format: nil)
        if value.is_a?(Hash) || (value.is_a?(String) && format.nil? && value.lstrip.start_with?('{') && GeoJSON.valid?(value))
          GeoJSON.new(value, srid).to_ewkt
        elsif value.is_a?(String) && value =~ /\A[A-F0-9]+\z/
          wkb_factory = srid.nil? ? factory : RGeo::Geos.factory(srid: srid)
          generate_ewkt(wkb_factory.parse_wkb(value))
        elsif value.is_a?(String) && format.to_s == 'gml'
          GML.new(value, srid).to_ewkt
        elsif value.is_a?(String) && format.to_s == 'kml'
          KML.new(value, srid).to_ewkt
        elsif value.is_a?(String)
          value
        else
          raise ArgumentError.new("Cannot convert #{value.class.name} to a geometry")
        end
      end

      def factory_options
        {
          wkt_generator: { type_format: :ewkt, emit_ewkt_srid: true, convert_case: :upper },
          wkt_parser: { support_ewkt: true },
          wkb_generator: { type_format: :ewkb, emit_ewkb_srid: true, hex_format: true },
          wkb_parser: { support_ewkb: true }
        }
      end

      def geos_factory(srid)
        RGeo::Geos.factory(srid: srid, **factory_options)
      end

      def projected_factory(srid)
        factory = RGeo::Geographic.projected_factory(
          srid: srid,
          projection_srid: 6933,
          projection_proj4: '+proj=cea +lon_0=0 +lat_ts=30 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs',
          **factory_options
        )
        factory.set_property(:uses_lenient_assertions, true) if factory.respond_to?(:set_property)
        factory
      end
  end
end

require 'geo/geometry'
require 'geo/bounding_box'
require 'geo/geo_json'
require 'geo/gml'
require 'geo/kml'
require 'geo/svg'
