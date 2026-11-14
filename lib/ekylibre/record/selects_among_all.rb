# frozen_string_literal: true

module Ekylibre
  module Record
    # Ensures only one record has a boolean column (by default: by_default) set
    # among all records (or among records with the same scope columns).
    module SelectsAmongAll #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Options:
        # - scope: column(s) defining groups in which only one record is selected
        # - subset: scope method restricting the records taken in account
        # - if: method name which must return true to select a record
        def selects_among_all(*columns)
          options = columns.extract_options!
          columns = [:by_default] if columns.empty?

          scope_columns = Array(options[:scope]).map(&:to_sym)
          unless options[:scope].nil? || options[:scope].is_a?(Symbol) || options[:scope].is_a?(Array)
            raise ArgumentError.new('Scope must be given as a Symbol or an Array of Symbol')
          end

          model = table_name.classify.constantize
          subset = options[:subset]
          condition = options[:if]

          # Records among which the column is unique
          selection_scope = lambda do |record|
            relation = subset ? model.public_send(subset) : model.all
            scope_columns.any? ? relation.where(scope_columns.index_by(&:itself).transform_values { |c| record.public_send(c) }) : relation
          end
          selectable = ->(record) { condition.nil? || record.public_send(condition) }

          columns.each do |column|
            # before_save (not before_create/update) to keep the original
            # order with the other before_save callbacks of the model
            before_save(:"set_#{column}_if_first", if: :new_record?)
            before_save(:"set_#{column}_if_alone", unless: :new_record?)
            after_save(:"ensure_#{column}_uniqueness")

            define_method("set_#{column}") do
              return false unless selectable.call(self)

              update_column(column, true)
            end

            define_method("set_#{column}!") do
              raise "Cannot selects #{column}" unless selectable.call(self)

              update!(column => true)
            end

            define_method("set_#{column}_if_first") do
              return unless selectable.call(self)

              self[column] = true unless selection_scope.call(self).where(column => true).any?
            end

            define_method("set_#{column}_if_alone") do
              return unless selectable.call(self)

              self[column] = true unless selection_scope.call(self).where(column => true).where.not(id: id).any?
            end

            define_method("ensure_#{column}_uniqueness") do
              return unless selectable.call(self) && self[column]

              selection_scope.call(self).where(column => true).where.not(id: id).update_all(column => false)
            end

            define_singleton_method(column) do |*values|
              if values.size != scope_columns.size || values.any?(&:nil?)
                raise ArgumentError.new("#{scope_columns.size} arguments expected: #{scope_columns.join(', ')}")
              end

              find_by(scope_columns.zip(values).to_h.merge(column => true))
            end
          end
        end
      end
    end
  end
end
