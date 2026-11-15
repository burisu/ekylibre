# frozen_string_literal: true

require 'liquid'

module Ekylibre
  module DocumentManagement
    # Renders a DocumentTemplate (Liquid HTML) with printer data
    class HtmlRenderer
      BASE_CSS = Rails.root.join('config', 'reporting', 'base.css')

      class << self
        def build
          new(template_provider: Ekylibre::DocumentManagement::TemplateFileProvider.build)
        end
      end

      attr_reader :template_provider

      def initialize(template_provider:)
        @template_provider = template_provider
      end

      # @param [DocumentTemplate] template
      # @param [PrinterBase] printer
      # @return [String] HTML
      def render(template:, printer:)
        path = template_provider.find_by_template(template)
        raise ArgumentError.new("No HTML template found for #{template&.nature}") if path.nil? || !File.exist?(path)

        report = HtmlReport.new
        printer.generate(report)
        render_source(File.read(path), report)
      end

      # @param [String] source Liquid HTML
      # @param [HtmlReport] report
      def render_source(source, report)
        liquid = Liquid::Template.parse(source, error_mode: :strict)
        liquid.render!({ 's0' => report.to_scope, 'base_css' => base_css }, filters: [ReportFilters], strict_filters: true)
      end

      private

        def base_css
          @base_css ||= BASE_CSS.exist? ? BASE_CSS.read : ''
        end
    end
  end
end
