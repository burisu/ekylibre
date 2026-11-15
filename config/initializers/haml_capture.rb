# frozen_string_literal: true

# Since Rails 7.1, `capture` swaps the content of `@output_buffer` directly,
# while Haml 5 redirects `output_buffer` (used by `concat`) to the Haml
# buffer during Haml rendering. Helpers using `concat` inside a block
# (`content_tag(:div) { concat(...) }`) called from a Haml template then
# wrote their content outside of the tag and got the escaped Haml buffer
# inside. During Haml rendering, Ruby blocks are captured through
# `with_output_buffer` again, as with Rails 5.2.
module HamlCaptureCompatibility
  def capture(*args, &block)
    return super unless block && respond_to?(:is_haml?) && is_haml? && !block_is_haml?(block)

    value = nil
    # Haml handles its buffer as a String (as ActionView::OutputBuffer was
    # with Rails 5.2)
    buffer = with_output_buffer(ActiveSupport::SafeBuffer.new) { value = yield(*args) }
    string = buffer.presence || value
    case string
    when ActionView::OutputBuffer then string.to_s
    when ActiveSupport::SafeBuffer then string
    when String then ERB::Util.html_escape(string)
    end
  end
end

ActiveSupport.on_load(:action_view) do
  prepend HamlCaptureCompatibility
end
