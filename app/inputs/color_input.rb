# frozen_string_literal: true

class ColorInput < SimpleForm::Inputs::Base
  def input(wrapper_options = nil)
    input_html_classes.unshift('color')
    input_html_options[:type] ||= 'color' if html5?

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end
