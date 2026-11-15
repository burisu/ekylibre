module Ekylibre
  module Record #:nodoc:
    module Dependents
      # Returns true if the record has records in one of its has_one, has_many
      # or has_and_belongs_to_many associations
      def has_dependents?
        self.class.reflect_on_all_associations.select { |r| r.macro.to_s.start_with?('has_') }.any? do |reflection|
          reflection.macro == :has_one ? public_send(reflection.name).present? : public_send(reflection.name).first.present?
        end
      end
    end
  end
end
