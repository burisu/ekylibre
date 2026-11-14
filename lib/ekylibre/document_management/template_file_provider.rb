# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    class TemplateFileProvider
      DEFAULT_ROOT_PATH = Rails.root.join('config', 'locales').freeze

      class << self
        def build(locale: ::I18n.locale.to_s)
          new(
            locale: locale,
            root_path: DEFAULT_ROOT_PATH
          )
        end
      end

      attr_reader :locale, :root_path

      # @param [String] locale
      # @param [Pathname] root_path
      def initialize(locale:, root_path:)
        @locale = locale
        @root_path = root_path
      end

      # @param [String] nature
      # @return [Pathname, nil]
      def find_by_nature(nature)
        html_paths(nature).detect(&:exist?)
      end

      # @param [DocumentTemplate] template
      # @return [Pathname, nil]
      def find_by_template(template)
        if template.nil?
          nil
        elsif template.managed?
          find_by_nature template.nature
        else
          template.source_path
        end
      end

      private

        def html_paths(nature)
          [locale, 'eng', 'fra'].uniq.map { |l| root_path.join(l, 'reporting', "#{nature}.html") }
        end
    end
  end
end
