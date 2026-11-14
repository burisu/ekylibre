# frozen_string_literal: true

require 'open3'

module Ekylibre
  module DocumentManagement
    # Converts odf-report ODT templates to Liquid HTML templates with
    # bin/odt2liquid (used for templates uploaded by users).
    class OdtConverter
      class ConversionError < StandardError; end

      SCRIPT = Rails.root.join('bin', 'odt2liquid')

      class << self
        # Names of tables, sections and images filled by printers
        def dynamic_names
          @dynamic_names ||= Dir.glob(Rails.root.join('app', '{services,jobs,controllers}', '**', '*.rb')).flat_map do |file|
            File.read(file).scan(/add_(?:table|section|image)\(?\s*[:'"]([A-Za-z0-9_-]+)/).flatten
          end.map { |name| Ekylibre::DocumentManagement::HtmlReport.key(name) }.uniq.sort
        end
      end

      # @param [String, Pathname] odt_path
      # @return [String] Liquid HTML
      def convert(odt_path)
        Tempfile.create(['dynamic_names', '.txt']) do |names|
          names.write(self.class.dynamic_names.join("\n"))
          names.flush
          output, error, status = Open3.capture3('python3', SCRIPT.to_s, odt_path.to_s, names.path)
          raise ConversionError.new("Cannot convert #{odt_path}: #{error}") unless status.success?

          output
        end
      end
    end
  end
end
