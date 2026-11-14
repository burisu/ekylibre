# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    # Builds a document (HTML rendered from a Liquid template) given a
    # DocumentTemplate and a PrinterBase, and converts it to PDF with WeasyPrint.
    class DocumentGenerator
      class << self
        def build
          converter = if Rails.env.test?
                        Ekylibre::DocumentManagement::TestingPdfConverter.build
                      else
                        Ekylibre::DocumentManagement::PdfConverter.build
                      end
          new(renderer: Ekylibre::DocumentManagement::HtmlRenderer.build, pdf_converter: converter)
        end
      end

      # @return [HtmlRenderer]
      attr_reader :renderer

      # @return [PdfConverter]
      attr_reader :pdf_converter

      def initialize(renderer:, pdf_converter:)
        @renderer = renderer
        @pdf_converter = pdf_converter
      end

      # @param [DocumentTemplate] template
      # @param [PrinterBase] printer
      # @return [String] HTML
      def generate_html(template:, printer:)
        renderer.render(template: template, printer: printer)
      end

      # @param [DocumentTemplate] template
      # @param [PrinterBase] printer
      # @return [String] PDF bytes
      def generate_pdf(template:, printer:)
        pdf_converter.convert_html(generate_html(template: template, printer: printer))
      end
    end
  end
end
