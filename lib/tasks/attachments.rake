# frozen_string_literal: true

namespace :attachments do
  # Former Paperclip storage paths, relative to private/<tenant>/attachments
  paperclip_paths = {
    picture: ->(record, extension) { File.join(record.class.name.underscore.pluralize, 'pictures', format('%09d', record.id).scan(/\d{3}/), "original#{extension}") },
    file: ->(record, extension) { File.join('documents', format('%09d', record.id).scan(/\d{3}/), "original#{extension}") },
    archive: ->(record, extension) { File.join('imports', record.id.to_s, "original#{extension}") },
    import_file: ->(record, extension) { File.join('financial_year_exchanges', record.id.to_s, "original#{extension}") },
    reference_source: ->(record, _extension) { File.join('guides', record.id.to_s, 'source.xml') }
  }

  attachments = {
    'Entity' => :picture, 'Product' => :picture, 'ProductNature' => :picture,
    'ProductNatureVariant' => :picture, 'Issue' => :picture,
    'Document' => :file, 'Import' => :archive, 'FinancialYearExchange' => :import_file,
    'Guide' => :reference_source
  }

  desc 'Copies the Paperclip files of all tenants (or TENANT) into Active Storage'
  task migrate_to_active_storage: :environment do
    tenants = ENV['TENANT'] ? [ENV['TENANT']] : Ekylibre::Tenant.list
    tenants.each do |tenant|
      Ekylibre::Tenant.switch(tenant) do
        root = Ekylibre::Tenant.private_directory.join('attachments')
        attachments.each do |model_name, name|
          model = model_name.constantize
          scope = model.unscoped.where.not("#{name}_file_name" => nil)
          scope = scope.where.not(id: ActiveStorage::Attachment.where(record_type: model.base_class.name, name: name.to_s).select(:record_id))
          copied = missing = 0
          scope.find_each do |record|
            file_name = record["#{name}_file_name"]
            path = root.join(paperclip_paths[name].call(record, File.extname(file_name)))
            unless path.exist?
              missing += 1
              next
            end

            blob = File.open(path, 'rb') do |io|
              ActiveStorage::Blob.create_and_upload!(io: io, filename: file_name, content_type: record["#{name}_content_type"])
            end
            # Attached without callbacks: records are not otherwise modified
            ActiveStorage::Attachment.create!(name: name.to_s, record_type: model.base_class.name, record_id: record.id, blob: blob)
            copied += 1
          end
          puts "#{tenant}: #{model_name}##{name}: #{copied} copied, #{missing} missing" if copied + missing > 0
        end
      end
    end
  end
end
