# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    class TestingPdfConverter
      class << self
        def build
          new(file: Rails.root.join('test', 'fixture-files', 'document_management', 'dummy_pdf.pdf'))
        end
      end

      # @param [Pathname] file
      def initialize(file:)
        @file = file
      end

      # @param [String] _html
      def convert_html(_html, base_url: nil)
        file.binread
      end

      private

        # @return [Pathname]
        attr_reader :file
    end
  end
end
