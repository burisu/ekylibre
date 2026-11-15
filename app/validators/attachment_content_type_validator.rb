# frozen_string_literal: true

# Validates the content type of an Active Storage attachment:
#   validates :picture, attachment_content_type: { with: /\Aimage/ }
class AttachmentContentTypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.respond_to?(:attached?) && value.attached?

    content_type = value.blob.content_type.to_s
    allowed = Array(options[:with] || options[:in])
    return if allowed.any? { |type| type.is_a?(Regexp) ? type.match?(content_type) : type.to_s == content_type }

    record.errors.add(attribute, options[:message] || :invalid, content_type: content_type)
  end
end
