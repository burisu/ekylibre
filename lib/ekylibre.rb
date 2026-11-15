module Ekylibre
  require_relative 'ekylibre/version'
  CSV = ::CSV.freeze

  class << self
    # Deprecation warnings of the application (see config.active_support.deprecation)
    def deprecator
      @deprecator ||= ActiveSupport::Deprecation.new('next major release', 'Ekylibre')
    end

    def http_languages
      ::I18n.available_locales.each_with_object({}) do |l, h|
        h['i18n.iso2'.t(locale: l)] = l
        h
      end
    end

    # Return root path of Ekylibre
    def root
      Rails.root
    end

    # Returns Ekylibre Version
    def version
      Ekylibre::VERSION
    end

    # Returns list of themes
    def themes
      unless @themes
        Dir.chdir(root.join('app', 'themes')) do
          @themes = Dir.glob('*')
        end
      end
      @themes
    end

    def load_integrations
      Dir.glob(Rails.root.join('app', 'integrations', '**', '*.rb')).each do |file|
        require file
      end
      Ekylibre::Plugin.load_integrations
    end

    # Returns all helps files indexed by locale and controller-action
    @helps = nil
    def helps
      return @helps unless @helps.nil?

      @helps = HashWithIndifferentAccess.new
      ::I18n.available_locales.each do |locale|
        @helps[locale] = HashWithIndifferentAccess.new
        locales_dir = root.join('config', 'locales', locale.to_s, 'help')
        Dir[locales_dir.join('**', '*.md')].sort.each do |file|
          path = Pathname.new(file).relative_path_from(locales_dir)
          File.open(file, 'rb:UTF-8') do |f|
            help = { title: f.read[/^#\s*(.*)$/, 1].strip, name: path.to_s.gsub(/\.md$/, ''), file: file }
            if help[:title].present?
              @helps[locale][path.to_s.gsub(/\.md$/, '')] = help
            end
          end
        end
      end
      @helps
    end
  end
end
