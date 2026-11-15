require 'tilt/coffee'

# i18n-complements core extensions pass options positionally, which Ruby 3
# no longer converts to keywords
[::String, ::Symbol].each do |klass|
  klass.class_eval do
    def translate(options = {})
      ::I18n.translate(self, **options)
    end
    alias_method :t, :translate
  end
end

[::String, ::TrueClass, ::FalseClass, ::Numeric, ::Date, ::DateTime, ::Time].each do |klass|
  klass.class_eval do
    def localize(options = {})
      ::I18n.localize(self, **options)
    end
    alias_method :l, :localize
  end
end

if defined? Encoding
  Encoding.default_internal = Encoding::UTF_8
  Encoding.default_external = Encoding::UTF_8
end

class ::String
  def tl(options = {}, **keywords)
    ::I18n.translate('labels.' + self, **options, **keywords)
  end
end

class ::Symbol
  def tl(options = {}, **keywords)
    ::I18n.translate('labels.' + to_s, **options, **keywords)
  end

  def ta(options = {}, **keywords)
    ::I18n.translate('rest.actions.' + to_s, **options, **keywords)
  end

  def tn(options = {}, **keywords)
    ::I18n.translate('notifications.messages.' + to_s, **options, **keywords)
  end

  # Translates with interpolated values emphasized and escaped
  def th(options = {}, **keywords)
    options = options.merge(keywords).to_h do |k, v|
      if %i[locale scope default].include?(k) || v.html_safe?
        [k, v]
      else
        [k, ('<em>' + CGI.escapeHTML(v.to_s) + '</em>').html_safe]
      end
    end
    tl(**options).html_safe
  end
end

class ::Time
  def to_usec
    (utc.to_f * 1000).to_i
  end

  def round_off(interval = 60)
    Time.at((to_f / interval).round * interval).utc
  end
end

class ::Numeric
  # FROM ActiveSupport 6.0
  def minutes
    ActiveSupport::Duration.minutes(self)
  end
  alias minute minutes

  # FROM ActiveSupport 6.0
  def hours
    ActiveSupport::Duration.hours(self)
  end
  alias hour hours

  def semester
    (self * 6).months
  end

  def trimester
    (self * 3).months
  end

  alias trimesters trimester
  alias semesters semester

  def rounded_localize(precision: 2, **options)
    round(precision).localize(precision: precision, **options)
  end

  alias round_l rounded_localize
end

class ::BigDecimal
  # Overwrite badly bigdecimal
  # TODO: What to do for that ?
  def to_f
    to_s('F').to_f
  end
end

class ::Array
  def jsonize_keys
    map do |v|
      (v.respond_to?(:jsonize_keys) ? v.jsonize_keys : v)
    end
  end
end

class ::Hash
  def jsonize_keys
    deep_transform_keys do |key|
      key.to_s.camelize(:lower)
    end
  end

  def deep_compact
    each_with_object({}) do |pair, hash|
      k = pair.first
      v = pair.second
      v2 = (v.is_a?(Hash) ? v.deep_compact : v)
      hash[k] = v2 unless v2.nil? || (v2.is_a?(Hash) && v2.empty?)
      hash
    end
  end

  # Build a struct from the hash
  def to_struct
    OpenStruct.new(self)
  end
end

module Ekylibre
  module I18n
    module ContextualModelHelpers
      def tc(key, options = {}, **keywords)
        ::I18n.translate("models.#{model_name.singular}.#{key}", **options, **keywords)
      end
    end

    module ContextualModelInstanceHelpers
      def tc(key, options = {}, **keywords)
        ::I18n.translate("models.#{self.class.model_name.singular}.#{key}", **options, **keywords)
      end
    end

    module ContextualHelpers
      def tl(key, options = {}, **keywords)
        ::I18n.translate("labels.#{key}", **options, **keywords)
      end
    end
  end
end

ActionController::Base.send :extend, Ekylibre::I18n::ContextualHelpers
ActionController::Base.send :include, Ekylibre::I18n::ContextualHelpers
ActiveRecord::Base.send :extend, Ekylibre::I18n::ContextualModelHelpers
ActiveRecord::Base.send :include, Ekylibre::I18n::ContextualModelInstanceHelpers
ActionView::Base.send :include, Ekylibre::I18n::ContextualHelpers

module ActiveModel
  module Validations
    module SymbolHandlingClusitivity
      private

        # Redefining the #include? method to make sure we only pass strings
        # to be validated instead of "sometime strings, sometime symbols"
        def include?(record, value)
          value = value.to_s if value.is_a? Symbol
          super record, value
          # `super` here references ActiveModel::Validations::Clusitivity#include?
        end
    end

    # Including new module in the validators that use Clusivity
    InclusionValidator.include SymbolHandlingClusitivity
    ExclusionValidator.include SymbolHandlingClusitivity
  end
end

# TODO: Get rid of this once the switch to Rails 5 has been made
module ActiveSupport
  class Duration
    ISO_INDEX_UNIT = { '1' => :year, '2' => :month, '3' => :day, '4' => :hour, '5' => :minute, '6' => :second }

    class << self
      # FROM ActiveSupport 6.0
      def seconds(value) #:nodoc:
        new(value, [[:seconds, value]])
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def minutes(value) #:nodoc:
        new(value * SECONDS_PER_MINUTE, [[:minutes, value]])
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def hours(value) #:nodoc:
        new(value * SECONDS_PER_HOUR, [[:hours, value]])
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def days(value) #:nodoc:
        new(value * SECONDS_PER_DAY, [[:days, value]])
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def weeks(value) #:nodoc:
        new(value * SECONDS_PER_WEEK, [[:weeks, value]])
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def months(value) #:nodoc:
        new(value * SECONDS_PER_MONTH, [[:months, value]])
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def years(value) #:nodoc:
        new(value * SECONDS_PER_YEAR, [[:years, value]])
      end unless ActiveSupport::Duration.methods.include?(:parse)

      def parse(string)
        hourly_format_match = string.match(/\A(\d{2}):(\d{2}):(\d{2})\z/)
        daily_format_match = string.match(/\A(\d+) days\z/)
        iso_format_match = string.match(/\AP(?:(\d*)Y)?(?:(\d*)M)?(?:(\d*)D)?(?:T(?:(\d*)H)?(?:(\d*)M)?(?:(\d*)S)?)?/)

        if hourly_format_match
          hourly_format_match[1].to_i.hour + hourly_format_match[2].to_i.minute + hourly_format_match[3].to_i.second
        elsif daily_format_match
          daily_format_match[1].to_i.day
        elsif iso_format_match
          (1..6).map { |int| iso_format_match[int] ? iso_format_match[int].to_i.send(ISO_INDEX_UNIT[int.to_s]) : nil }.compact.reduce(:+)
        end
      end unless ActiveSupport::Duration.methods.include?(:parse)
    end

    # FROM ActiveSupport 6.0
    def iso8601(precision: nil)
      ISO8601Serializer.new(self, precision: precision).serialize
    end unless ActiveSupport::Duration.instance_methods.include?(:iso8601)

    def in_full(unit)
      to_i / PARTS_IN_SECONDS[unit.to_s.pluralize.to_sym]
    end

    # FROM ActiveSupport 6.0
    class ISO8601Serializer # :nodoc:
      DATE_COMPONENTS = %i(years months days)

      def initialize(duration, precision: nil)
        @duration = duration
        @precision = precision
      end

      # Builds and returns output string.
      def serialize
        parts, sign = normalize
        return "PT0S" if parts.empty?

        output = +"P"
        output << "#{parts[:years]}Y" if parts.key?(:years)
        output << "#{parts[:months]}M" if parts.key?(:months)
        output << "#{parts[:days]}D" if parts.key?(:days)
        output << "#{parts[:weeks]}W" if parts.key?(:weeks)
        time = +""
        time << "#{parts[:hours]}H" if parts.key?(:hours)
        time << "#{parts[:minutes]}M" if parts.key?(:minutes)
        if parts.key?(:seconds)
          time << "#{sprintf(@precision ? "%0.0#{@precision}f" : '%g', parts[:seconds])}S"
        end
        output << "T#{time}" unless time.empty?
        "#{sign}#{output}"
      end

      private

      # Return pair of duration's parts and whole duration sign.
      # Parts are summarized (as they can become repetitive due to addition, etc).
      # Zero parts are removed as not significant.
      # If all parts are negative it will negate all of them and return minus as a sign.
      def normalize
        parts = @duration.parts.each_with_object(Hash.new(0)) do |(k, v), p|
          p[k] += v unless v.zero?
        end

        # Convert weeks to days and remove weeks if mixed with date parts
        if week_mixed_with_date?(parts)
          parts[:days] += parts.delete(:weeks) * SECONDS_PER_WEEK / SECONDS_PER_DAY
        end

        # If all parts are negative - let's make a negative duration
        sign = ""
        if parts.values.all? { |v| v < 0 }
          sign = "-"
          parts.transform_values!(&:-@)
        end
        [parts, sign]
      end

      def week_mixed_with_date?(parts)
        parts.key?(:weeks) && (parts.keys & DATE_COMPONENTS).any?
      end
    end
  end
end

# Factories serialized by old RGeo versions use the `projector_class` key
# (`projectorclass` since RGeo 2.x)
module RGeo
  module Geographic
    module LegacyProjectorClassKey
      def init_with(coder)
        coder["projectorclass"] ||= coder["projector_class"] if coder.respond_to?(:[]=) && coder["projector_class"]
        super
      end
    end
    Factory.prepend(LegacyProjectorClassKey)
  end
end

# RGeo 3.0 projected geometries call unsafe_simplify(_preserve_topology) on
# their projection, which GEOS CAPI geometries only expose without prefix
module RGeo
  module Geos
    module CAPIGeometryMethods
      alias_method :unsafe_simplify, :simplify unless method_defined?(:unsafe_simplify)
      alias_method :unsafe_simplify_preserve_topology, :simplify_preserve_topology unless method_defined?(:unsafe_simplify_preserve_topology)
    end
  end
end
