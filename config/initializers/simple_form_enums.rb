# frozen_string_literal: true

# Enumerated attributes (Ekylibre::Record::HasEnum) are rendered as selects
# whose options are their translated values, unless told otherwise.
module SimpleFormEnumInputs
  def input(attribute_name, options = {}, &block)
    add_enum_input_options(attribute_name, options)
    super
  end

  def input_field(attribute_name, options = {})
    add_enum_input_options(attribute_name, options)
    super
  end

  private

    def add_enum_input_options(attribute_name, options)
      klass = object.class
      return unless klass.respond_to?(:enum_attributes)

      attribute = klass.enum_attributes[attribute_name.to_s]
      return unless attribute

      options[:collection] ||= attribute.options
      options[:as] ||= :select
    end
end

SimpleForm::FormBuilder.prepend(SimpleFormEnumInputs)
