# frozen_string_literal: true

# Replaces the validates_timeliness gem for the subset used in Ekylibre:
#
#   validates :stopped_on, timeliness: { on_or_after: ->(r) { r.started_on }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
#
# Supported options: :on_or_after, :on_or_before (value, Proc with 0 or 1 arg, or Symbol) and :type (:date, :datetime).
class TimelinessValidator < ActiveModel::EachValidator
  RESTRICTIONS = %i[on_or_after on_or_before].freeze

  def validate_each(record, attribute, value)
    type = options[:type] || :datetime

    if value.nil?
      raw = record.respond_to?(:"#{attribute}_before_type_cast") ? record.public_send(:"#{attribute}_before_type_cast") : nil
      record.errors.add(attribute, :"invalid_#{type}") if raw.present?
      return
    end

    value = cast(value, type)
    return record.errors.add(attribute, :"invalid_#{type}") if value.nil?

    RESTRICTIONS.each do |restriction|
      next unless options.key?(restriction)

      limit = cast(evaluate(options[restriction], record), type)
      next if limit.nil?

      valid = restriction == :on_or_after ? value >= limit : value <= limit
      next if valid

      record.errors.add(attribute, restriction, restriction: I18n.localize(limit))
    end
  end

  private

    def evaluate(option, record)
      case option
      when Proc then option.arity.zero? ? option.call : option.call(record)
      when Symbol then record.send(option)
      else option
      end
    end

    def cast(value, type)
      case type
      when :date
        value.respond_to?(:to_date) ? value.to_date : Date.parse(value.to_s)
      else
        if value.is_a?(Date) && !value.is_a?(DateTime)
          value.in_time_zone
        elsif value.respond_to?(:in_time_zone)
          value.in_time_zone
        else
          Time.zone.parse(value.to_s)
        end
      end
    rescue ArgumentError, TypeError
      nil
    end
end
