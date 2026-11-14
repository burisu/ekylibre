# frozen_string_literal: true

module HasInterval
  extend ActiveSupport::Concern

  module ClassMethods
    def has_interval(*columns)
      columns.each do |column|
        define_method column do
          value = self[column]
          # Rails >= 6.1 casts PostgreSQL intervals to ActiveSupport::Duration
          value.is_a?(String) && value.present? ? ActiveSupport::Duration.parse(value) : value.presence
        end

        define_method "#{column}=" do |value|
          self[column] = if value.blank?
                           nil
                         elsif value.is_a?(ActiveSupport::Duration)
                           value.iso8601
                         elsif value.is_a?(String) && ActiveSupport::Duration.parse(value)
                           value
                         else
                           raise ArgumentError.new("Invalid duration: #{value}")
                         end
        end
      end
    end
  end
end
