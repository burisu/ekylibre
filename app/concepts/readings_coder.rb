# frozen_string_literal: true

class ReadingsCoder
  SERIALIZE = Hash.new { proc { |_, value| value } }
                  .tap { |h| h[Measure] = proc { |_, value| value.to_s } }
                  .tap { |h| h[Geo::Point] = proc { |_, value| value.to_ewkt } }
                  .tap { |h| h[Geo::MultiPolygon] = proc { |_, value| value.to_ewkt } }

  UNSERIALIZE = Hash.new { proc { |klass, value| klass.new(value) } }
                    .tap { |h| h[Geo::MultiPolygon] = proc { |_, value| Geo.new_geometry(value) } }
                    .tap { |h| h[Geo::Point] = proc { |_, value| Geo.new_geometry(value) } }
                    .tap { |h| h[FalseClass] = proc { |_, _| false } }
                    .tap { |h| h[TrueClass] = proc { |_, _| true } }
                    .tap { |h| h[Integer] = proc { |_, value| value.to_i } }
                    .tap { |h| h[String] = proc { |_, value| value } }
                    .tap { |h| h[Integer] = proc { |_, value| value.to_i } }
                    .tap { |h| h[Integer] = proc { |_, value| value.to_i } }
                    .tap { |h| h[Float] = proc { |_, value| value.to_f } }
                    .tap { |h| h[BigDecimal] = proc { |_, value| BigDecimal(value) } }
                    .freeze

  # Class names stored by former versions (charta gem)
  LEGACY_CLASS_NAMES = {
    'Charta::MultiPolygon' => 'Geo::MultiPolygon',
    'Charta::Point' => 'Geo::Point'
  }.freeze

  class << self
    def load(json)
      hash = if json.is_a? Hash
               json
             elsif json.present? && json.is_a?(String)
               JSON.parse(json)
             else
               {}
             end

      hash.transform_values do |(klass, value)|
        klass = LEGACY_CLASS_NAMES.fetch(klass, klass).constantize

        UNSERIALIZE[klass][klass, value]
      end
    end

    def dump(hash)
      hash.compact.transform_values do |value|
        klass = value.class

        [klass.name, SERIALIZE[klass][klass, value]]
      end.to_json
    end
  end
end
