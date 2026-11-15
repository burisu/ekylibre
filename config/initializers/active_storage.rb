# frozen_string_literal: true

Rails.application.config.active_storage.variant_processor = :mini_magick
# Variants are recorded (ActiveStorage::VariantRecord) so they are processed once
Rails.application.config.active_storage.track_variants = true
# Attaching a file does not touch the record: records use optimistic locking
Rails.application.config.active_storage.touch_attachment_records = false

ActiveSupport.on_load(:active_storage_blob) do
  # Blob keys are prefixed by the tenant ("<tenant>/<token>"): files of a
  # tenant are grouped by storage services and a key cannot be mistaken for
  # another tenant's one. Variants and previews are blobs too.
  def key
    self[:key] ||= [
      Ekylibre::Tenant.current.presence || 'public',
      self.class.generate_unique_secure_token(length: ActiveStorage::Blob::MINIMUM_TOKEN_LENGTH)
    ].join('/')
  end

  # Path of the blob content on the local file system: the stored file with a
  # disk service, a temporary copy otherwise (kept while the blob is in memory)
  def local_path
    return service.path_for(key) if service.respond_to?(:path_for)

    @local_copy ||= Tempfile.new(['blob', filename.extension_with_delimiter], binmode: true).tap do |file|
      download { |chunk| file.write(chunk) }
      file.flush
    end
    @local_copy.path
  end
end
