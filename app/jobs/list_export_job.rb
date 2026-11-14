# frozen_string_literal: true

class ListExportJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  protected

    # Rebuilds the list declared in +controller+ (no code is evaluated) and
    # exports all its records with the request +params+.
    def perform(user:, controller:, list:, params:, file_name:, format:, file_extension:)
      controller_class = controller.safe_constantize
      raise ArgumentError.new("Invalid controller: #{controller}") unless controller_class.respond_to?(:active_list_table)

      table = controller_class.active_list_table(list)
      raise ArgumentError.new("Unknown list #{list} in #{controller}") unless table

      context = ActiveList::JobContext.new(params: params, current_user: user, controller_name: controller_class.controller_name)
      data = ActiveList::Exporters.new(table, context).generate(format)
      file = StringIO.new(data)

      document = Document.create!(key: "#{Time.now.to_i}-#{file_name.parameterize}",
                                  name: file_name,
                                  file: file,
                                  file_file_name: "#{file_name.parameterize}.#{file_extension}")

      user.notifications.create!(success_notification_params(document.id))
    rescue StandardError => error
      Rails.logger.error error
      Rails.logger.error error.backtrace.join("\n")
      ExceptionNotifier.notify_exception(error, data: { message: error })
      user.notifications.create!(error_notification_params(error.message))
    end

  private

    def error_notification_params(error)
      {
        message: 'error_during_file_generation',
        level: :error,
        interpolations: {
          error_message: error
        }
      }
    end

    def success_notification_params(document_id)
      {
        message: 'file_generated',
        level: :success,
        target_type: 'Document',
        target_url: backend_document_path(document_id),
        interpolations: {}
      }
    end
end
