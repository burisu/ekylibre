# frozen_string_literal: true

class ExportJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(params, user)
    params = JSON.load(params)
    klass = Aggeratio[params['id']]
    aggregator = klass.new(params)
    format = params['format']
    user = User.find(user)
    name = params['template'].to_i

    unless template = DocumentTemplate.find_active_template(name)
      raise StandardError.new("Can not find template for #{name.inspect}")
    end

    filename = "#{klass.human_name}.#{format}"

    key = params['key'] || SecureRandom.hex(2)
    # Export and send file
    begin
      # Print the aggregator with its template and archive the PDF
      printer = Printers::AggregatorPrinter.new(template: template, aggregator: aggregator, key: key)
      pdf = Ekylibre::DocumentManagement::DocumentGenerator.build.generate_pdf(template: template, printer: printer)
      document = Ekylibre::DocumentManagement::DocumentArchiver.build.archive_document(pdf_content: pdf, template: template, key: key, name: printer.document_name)
      path = document.file.path
      document_id = document.id
      # Send a notification to user
      notification = user.notifications.build(valid_generation_notification_params(path, filename, document_id))
    rescue => error
      # When error create a notification with error message
      Rails.logger.error error
      Rails.logger.error error.backtrace.join("\n")
      ExceptionNotifier.notify_exception(error, data: { message: error })
      notification = user.notifications.build(error_generation_notification_params(filename, params['id'], error.message))
    end
    notification.save
  end

  def error_generation_notification_params(_filename, id, error)
    {
      message: 'error_during_file_generation',
      level: :error,
      target_type: 'Document',
      target_url: backend_export_path(id),
      interpolations: {
        error_message: error
      }
    }
  end

  def valid_generation_notification_params(_path, _filename, document_id)
    {
      message: 'file_generated',
      level: :success,
      target_type: 'Document',
      target_url: backend_document_path(document_id),
      interpolations: {}
    }
  end

end
