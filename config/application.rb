require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/possibly'
require_relative '../lib/ekylibre/middleware/maintenance'

module Ekylibre
  class Application < Rails::Application
    # @return [Array<Ekylibre::Plugin::Base>]
    attr_reader :plugins

    def initialize(*args, **opts, &block)
      super

      @plugins = []
    end

    # @return [Procedo::ProcedureRegistry]
    def procedo_registry
      @procedo_registry ||= Procedo::ProcedureRegistry.new
    end

    # @return [Array<Ekylibre::Plugin::Theme>]
    def themes
      plugins.flat_map(&:themes).map { |name| Ekylibre::Plugin::Theme.new(name) }
    end

    # Rails 8.1 framework defaults, except the ones below which keep the
    # behaviour the application relies on
    config.load_defaults 8.1

    # lib/ files are required by name (config/initializers/20-start.rb)
    config.add_autoload_paths_to_load_path = true
    # Remote forms are still handled by jquery_ujs (form_with :local option)
    config.action_view.form_with_generates_remote_forms = true
    # Redirections to other hosts (OAuth, tenant subdomains, external links)
    config.action_controller.raise_on_open_redirects = false
    config.action_controller.action_on_open_redirect = :log
    # Jobs enqueued in transactions (callbacks) run as before, see
    # ApplicationJob for tenant handling
    config.active_job.enqueue_after_transaction_commit = false
    # Readonly attributes (currency, reference_name...) are assigned by forms
    # and callbacks: changes are ignored, as before Rails 7.1
    config.active_record.raise_on_assign_to_attr_readonly = false
    # Path relative redirections (redirect_back from tests and old links)
    # are kept, as before Rails 8.1
    config.action_controller.action_on_path_relative_redirect = :log
    # Inverse of has_many associations are not set on new records (Rails 6.1
    # default): records duplicated with their parameters (interventions...)
    # keep their own associations
    config.active_record.has_many_inversing = false
    config.active_record.automatic_scope_inversing = false
    # Callbacks run as before: after_commit callbacks in reverse order of
    # definition, on the instance saved last, before_committed! only on the
    # first instance of a record
    config.active_record.run_after_transaction_callbacks_in_order_defined = false
    config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction = true
    config.active_record.before_committed_on_all_records = false
    # Inserts send all columns, and presence of belongs_to is always checked
    config.active_record.partial_inserts = true
    config.active_record.belongs_to_required_validates_foreign_key = true
    config.active_record.generate_secure_token_on = :create
    # Raw SQL results (select_all/select_value) keep dates as strings
    config.active_record.postgresql_adapter_decode_dates = false
    # first/last without explicit order keep working on any model
    config.active_record.raise_on_missing_required_finder_order_columns = false
    # Same markup as before: button_to renders an input, stylesheets are
    # screen-only by default (print styles stay separate), no hidden field
    # for multiple file inputs, autocomplete="off" on hidden fields
    config.action_view.button_to_generates_button_tag = false
    config.action_view.apply_stylesheet_media_default = true
    config.active_storage.multiple_file_field_include_hidden = false
    config.action_view.remove_hidden_field_autocomplete = false
    config.action_view.sanitizer_vendor = Rails::HTML4::Sanitizer
    # Forms keep their utf8=✓ hidden field (search URLs unchanged)
    config.action_view.default_enforce_utf8 = true
    # JSON params are not wrapped in a root key automatically
    config.action_controller.wrap_parameters_by_default = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.autoloader = :zeitwerk
    # lib/ is loaded once (not reloaded) so it can be used by initializers
    config.autoload_once_paths << Rails.root.join('lib')
    Rails.autoloaders.once.ignore(
      # Not Ruby constants
      Rails.root.join('lib', 'assets'),
      Rails.root.join('lib', 'generators'),
      Rails.root.join('lib', 'tasks'),
      Rails.root.join('lib', 'templates'),
      # Loaded by Active Storage from config/storage.yml
      Rails.root.join('lib', 'active_storage'),
      # Monkey patches, required explicitly (config/initializers/20-start.rb)
      Rails.root.join('lib', 'state_machine'),
      Rails.root.join('lib', 'reporting.rb'),
      Rails.root.join('lib', 'safe_string.rb'),
      Rails.root.join('lib', 'ekylibre', 'plugin', 'routing.rb'),
      # Required before autoloading is set up (see above)
      Rails.root.join('lib', 'possibly.rb'),
      Rails.root.join('lib', 'ekylibre', 'middleware'),
      Rails.root.join('lib', 'ekylibre', 'version.rb')
    )
    # Test and development tools, loaded on demand only
    Rails.autoloaders.once.do_not_eager_load(
      Rails.root.join('lib', 'active_exchanger', 'test_case.rb'),
      Rails.root.join('lib', 'clean'),
      Rails.root.join('lib', 'ekylibre', 'testing'),
      Rails.root.join('lib', 'test')
    )
    Rails.autoloaders.main.ignore(Rails.root.join('app', 'themes'))
    Rails.autoloaders.each do |autoloader|
      autoloader.inflector.inflect(
        'csv' => 'CSV',
        'dsl' => 'DSL',
        'ebp' => 'EBP',
        'edi_exchanger' => 'EDIExchanger',
        'fec' => 'FEC',
        'fiea' => 'FIEA',
        'geo_json' => 'GeoJSON',
        'gml' => 'GML',
        'html' => 'HTML',
        'json' => 'JSON',
        'kml' => 'KML',
        'omniauth' => 'OmniAuth',
        'sql_compiler' => 'SQLCompiler',
        'svf' => 'SVF',
        'svg' => 'SVG',
        'upra' => 'UPRA',
        'xml' => 'XML'
      )
    end
    config.autoload_paths << Rails.root.join('app', 'models', 'bookkeepers')
    config.autoload_paths << Rails.root.join('app', 'models', 'lexicon')
    config.eager_load_paths += [Rails.root.join('lib'), Rails.root.join('app', 'models', 'bookkeepers'), Rails.root.join('app', 'models', 'lexicon')]

    # Legacy plugins (plugins/*/Plugfile, see Ekylibre::Plugin): their app/
    # directories must be known before autoloading is set up
    unless ENV['PLUGIN'] == 'false' || Rails.env.test?
      Dir.glob(Rails.root.join('plugins', '*', 'Plugfile')).sort.each do |plugfile|
        app = File.join(File.dirname(plugfile), 'app')
        dirs = Dir.glob(File.join(app, '{controllers,exchangers,guides,helpers,inputs,integrations,jobs,mailers,models}'))
        dirs += Dir.glob(File.join(app, '{controllers,models}', 'concerns'))
        config.autoload_paths += dirs
        config.eager_load_paths += dirs
      end
    end

    # We want to use the structure.sql file
    config.active_record.schema_format = :sql

    config.active_record.time_zone_aware_types = [:datetime, :time]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Confiure ActiveJob queue adapter
    config.active_job.queue_adapter = :solid_queue

    # Default starting from Rails 5
    # TODO: enable this when all optional belongs_to have been edited with 'optional: true'
    config.active_record.belongs_to_required_by_default = false

    # TODO: enable this when ready
    # config.action_controller.per_form_csrf_tokens = true
    # config.action_controller.forgery_protection_origin_check = true


    # Configure defaults for generators
    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
    end

    # APM
    # config.elastic_apm.service_name = ENV.fetch('APM_SERVICE_NAME', 'Ekylibre')

    config.middleware.insert_before 0, Ekylibre::Middleware::Maintenance

    config.middleware.use Rack::Cors do
      allow do
        origins /https:\/\/ekylibre.stoplight.io\.*/
        resource '*',
          headers: :any,
          methods: %i[get post put patch delete]
      end
    end

    # TODO: Rails 5 upgrade: check if removing this is OK
    # config.middleware.insert_after ActionDispatch::ParamsParser, ActiveSupport::XMLConverter

    initializer :register_core_plugin, before: :load_config_initializers do
      Ekylibre::Application.instance.plugins << Ekylibre::Core::Plugin.new
    end
  end
end
