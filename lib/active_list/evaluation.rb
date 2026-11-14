# frozen_string_literal: true

module ActiveList
  # Evaluates dynamic option values (Procs, Symbols) without any string eval.
  module Evaluation
    module_function

    # Evaluates a value in the given context.
    # Procs without argument are instance_exec'd in context, Procs with
    # arguments receive the record.
    def value(context, value, record = nil)
      return value unless value.is_a?(Proc)

      if value.arity.zero?
        context.instance_exec(&value)
      else
        context.instance_exec(record, &value)
      end
    end

    # Evaluates a record-oriented value: Symbols are sent to the record.
    def record_value(context, value, record)
      case value
      when Symbol then record.public_send(value)
      when Proc then value(context, value, record)
      else value
      end
    end

    # Deeply evaluates Hash/Array structures (used for conditions and URLs).
    def deep(context, value, record = nil)
      case value
      when Proc then value(context, value, record)
      when Hash then value.transform_values { |v| deep(context, v, record) }
      when Array then value.map { |v| deep(context, v, record) }
      else value
      end
    end
  end
end
