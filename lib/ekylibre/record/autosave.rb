module Ekylibre
  module Record
    # Saves associated records again after a record is saved or destroyed
    # (for their callbacks to compute their state from it).
    module Autosave #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def autosave(*reflections_list)
          options = { callbacks: %i[after_save after_destroy] }
          options = options.merge(reflections_list.pop) if reflections_list.last.is_a?(Hash)

          reflections = reflections_list.map do |name|
            reflect_on_association(name) ||
              raise(ArgumentError.new("Reflection #{name.inspect} unknown (#{reflect_on_all_associations.map(&:name).to_sentence} available)"))
          end

          method_name = (options[:method] || "autosave_#{reflections_list.join('_and_')}").to_sym
          define_method(method_name) do
            reflections.each do |reflection|
              records = %i[belongs_to has_one].include?(reflection.macro) ? [public_send(reflection.name)] : public_send(reflection.name).to_a
              records.compact.each do |record|
                next if record.destroyed? || record.marked_for_destruction?

                errors.add_from_record(record) unless record.reload.save
              end
            end
          end

          options[:callbacks].each { |callback| send(callback, method_name) }
        end
      end
    end
  end
end
