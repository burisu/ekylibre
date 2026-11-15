module Ekylibre
  module Record
    module Sums #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Sums columns of the children of a target and puts the results in the
        # target, without validations nor callbacks.
        #
        #   sums :sale, :items, :pretax_amount, :amount
        #   sums :fixed_asset, :depreciations, amount: :depreciated_amount
        def sums(target, children, *args)
          options = args.extract_options!
          args.each do |arg|
            raise ArgumentError.new("Unvalid type #{arg.inspect}:#{arg.class.name}") unless arg.is_a?(Symbol) || arg.is_a?(String)

            options[arg.to_sym] = arg.to_sym
          end
          method_name = (options.delete(:method) || "sums_#{children}_of_#{target}").to_sym
          callbacks = options.delete(:callbacks) || %i[after_save after_destroy]
          from = options.delete(:from)
          negate = options.delete(:negate)
          columns = options.to_h { |source, column| [source.to_sym, column.to_sym] }

          define_method(method_name) do
            parent = public_send(target)
            return unless parent

            totals = columns.values.uniq.index_with { 0 }
            parent.reload
            parent.public_send(children).find_each do |child|
              columns.each do |source, column|
                value = child.public_send(source)
                value = value.to_s.to_f if from
                if value.nil?
                  Rails.logger.warn 'Nil value in sums'
                  value = 0.0
                end
                totals[column] = negate ? totals[column] - value : totals[column] + value
              end
            end
            parent.update_columns(totals)
          end

          callbacks.each { |callback| send(callback, method_name) }
        end
      end
    end
  end
end
