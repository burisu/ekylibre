# frozen_string_literal: true

require 'open3'

module Ekylibre
  module DocumentManagement
    # Converts HTML to PDF with WeasyPrint (https://weasyprint.org)
    class PdfConverter
      class ConversionError < StandardError; end

      class << self
        def build
          new(command: ENV.fetch('WEASYPRINT_COMMAND', 'weasyprint'))
        end
      end

      attr_reader :command

      def initialize(command:)
        @command = command
      end

      # @param [String] html
      # @param [String] base_url used to resolve relative URLs (images...)
      # @return [String] PDF bytes
      def convert_html(html, base_url: Rails.root.to_s)
        output, error, status = Open3.capture3(command, '--base-url', base_url, '--encoding', 'utf-8', '-', '-',
                                               stdin_data: html, binmode: true)
        raise ConversionError.new("WeasyPrint failed (#{status.exitstatus}): #{error}") unless status.success?

        output
      end
    end
  end
end
