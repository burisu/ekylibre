# frozen_string_literal: true

module Ekylibre
  module Record
    module Acts
      # File attached with Active Storage.
      #
      #   has_file :archive
      #
      # The metadata columns of the former Paperclip attachments
      # (<name>_file_name, _content_type, _file_size, _updated_at, _fingerprint)
      # are kept up to date when they exist, and <name>_path gives a local path
      # to the content.
      module Attachable
        METADATA = {
          file_name: ->(blob) { blob.filename.to_s },
          content_type: ->(blob) { blob.content_type },
          file_size: ->(blob) { blob.byte_size },
          fingerprint: ->(blob) { blob.checksum },
          updated_at: ->(_blob) { Time.current }
        }.freeze

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def has_file(name, content_type: nil)
            name = name.to_s
            has_one_attached name
            validates name, attachment_content_type: { with: content_type } if content_type

            before_save(if: -> { attachment_changes[name].present? }) do
              store_attachment_metadata(name)
            end

            define_method("#{name}_path") do
              attachment = public_send(name)
              attachment.attached? ? attachment.blob.local_path : nil
            end
          end
        end

        # Local path of the file given to the attachment before it is uploaded
        def attachable_path(name)
          attachable = attachment_changes[name.to_s]&.attachable
          attachable = attachable[:io] if attachable.is_a?(Hash)
          if attachable.is_a?(ActiveStorage::Blob)
            attachable.local_path
          elsif attachable.respond_to?(:path) && attachable.path
            attachable.path
          elsif attachable.respond_to?(:read)
            @attachable_copies ||= {}
            @attachable_copies[name.to_s] ||= Tempfile.new('attachable', binmode: true).tap do |file|
              attachable.rewind if attachable.respond_to?(:rewind)
              IO.copy_stream(attachable, file)
              attachable.rewind if attachable.respond_to?(:rewind)
              file.flush
            end
            @attachable_copies[name.to_s].path
          end
        end

        private

          def store_attachment_metadata(name)
            blob = public_send(name).blob
            return unless blob

            METADATA.each do |field, value|
              column = "#{name}_#{field}"
              self[column] = value.call(blob) if has_attribute?(column)
            end
          end
      end
    end
  end
end
