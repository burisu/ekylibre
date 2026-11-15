# frozen_string_literal: true

module Geo
  # Encodes RGeo features as SVG path data (Y axis inverted)
  module SVG
    class << self
      def encode(feature)
        send("encode_#{Geo.underscore(feature.geometry_type.type_name)}", feature)
      end

      # Minimal SVG document with one path
      def document(path_attributes, svg_attributes)
        attributes = ->(hash) { hash.map { |k, v| %(#{k.to_s.tr('_', '-')}="#{ERB::Util.html_escape(v)}") }.join(' ') }
        +%(<svg xmlns="http://www.w3.org/2000/svg" #{attributes.call(svg_attributes)}><path #{attributes.call(path_attributes)}/></svg>)
      end

      private

        def encode_point(feature)
          "M#{coordinates(feature)}"
        end

        def encode_multi_point(feature)
          feature.map { |point| encode_point(point) }.join(' ')
        end

        def encode_line_string(feature)
          'M' + feature.points.map { |point| coordinates(point) }.join('L')
        end

        def encode_multi_line_string(feature)
          feature.map { |line_string| encode_line_string(line_string) }.join(' ')
        end

        def encode_polygon(feature)
          rings = [encode_line_string(feature.exterior_ring) + 'Z']
          feature.interior_rings.each { |ring| rings << encode_line_string(ring) + 'Z' }
          rings.join(' ')
        end

        def encode_multi_polygon(feature)
          feature.map { |polygon| encode_polygon(polygon) }.join(' ')
        end

        def encode_geometry_collection(feature)
          feature.map { |geometry| encode(geometry) }.join(' ')
        end

        def coordinates(feature)
          "#{feature.x},#{-1 * feature.y}"
        end
    end
  end
end
