# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

git_source(:gitlab) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://gitlab.com/#{repo_name}.git"
end

ruby '>= 3.3', '< 3.4'

gem 'actionpack-xml_parser', '~> 2.0'
gem 'rack-cors' # CORS policy
gem 'rails', '~> 7.2.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# IRB and CLI
gem 'fiddle'
gem 'irb', '~> 1.3'
gem 'rake', '~> 13.0'

# TO REMOVE ASAP
gem 'ffaker', '~> 2.0' # Should not be present in production. Is used to generate names for Products.

# Database
gem 'activemodel-serializers-xml', '~> 1.0'
gem 'activerecord-postgis-adapter', '~> 10.0'
gem 'pg', '~> 1.0'
gem 'scenic'

# Multi-tenancy
gem 'ros-apartment', '~> 3.1', require: 'apartment'

# Assets pipeline
gem 'coffee-rails', '~> 4.1'
gem 'sassc-rails', '~> 2.0'
gem 'sprockets', '< 4.0'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker', '~> 5.4'

# CSS
gem 'agric', github: 'ekylibre/agric', branch: 'master'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'font-awesome-sass', '~> 5.15'

# JS
gem 'cocoon', '~> 1.2'
gem 'jquery-rails', '~> 4.4'
gem 'jquery-ui-rails', '~> 6.0'
gem 'simple_calendar', '~> 2.4.0'
gem 'turbolinks', '~> 5.2.1'
gem 'twitter-typeahead-rails', '~> 0.11.1'

# Front
gem 'kaminari', '~> 1.1'
gem 'remotipart', '~> 1.2'
gem 'simple_form', '~> 5.1'

# View Engines
gem 'haml', '~> 5.2'
gem 'jbuilder', '~> 2.0'

# Ruby extensions
gem 'semantic', '~> 1.6'

# Exception analysis and metrics
# gem 'elastic-apm', '~> 3.4.0'
gem 'exception_notification', '~> 4.5'
gem 'redis-namespace', '~> 1.8'

# Manipulate map data
gem 'geocoder', '~> 1.6'
gem 'rgeo', '~> 3.0'
gem 'rgeo-geojson', '~> 2.1'
gem 'rgeo-proj4', '~> 4.0'
gem 'rgeo-shapefile', '~> 3.0'

# Background jobs
gem 'sidekiq', '~> 5.2'
gem 'sidekiq-cron', '~> 1.2'

# Reference data
# Vendored (0.9.8 pins zeitwerk ~> 2.4.0, incompatible with Rails 7)
gem 'onoma', path: 'vendor/gems/onoma'

# Parse LALR or LR-1 grammars
gem 'treetop', '~> 1.6'

# Models helpers
gem 'acts_as_list', '~> 1.0'
gem 'awesome_nested_set', '~> 3.5'
gem 'deep_cloneable', '~> 3.2'
gem 'draper', '~> 4.0'
gem 'enumerize', '~> 2.4'
gem 'paranoia', '~> 3.0' # Hide and restore records without actually deleting them
gem 'state_machines-activerecord', '~> 0.9'
# 0.100+ runs transitions in fibers, which deadlocks with ActiveRecord's connection lock
gem 'state_machines', '< 0.100'
gem 'uuidtools', '~> 2.2'

# Authentication & Authorization
gem 'devise', '~> 4.8'
gem 'devise-i18n-views', '~> 0.3.7'
gem 'devise_invitable', '~> 2.0'
gem 'googleauth'
gem 'omniauth', '~> 2.1'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-oauth2', '~> 1.8'

# Attachments
gem 'paperclip', '~> 5.3' # replaced by Active Storage at Rails 7.2
gem 'paperclip-document', '~> 0.0.11'

# Emailing
gem 'liquid', '>= 4.0'
gem 'tinymce-rails'
gem 'tinymce-rails-langs'

# I18n and localeapp
gem 'http_accept_language', '~> 2.1'
gem 'humanize', '~> 2.5'
gem 'i18n-complements', '>= 0.0.14'
gem 'i18n-js', '~> 3.8'

# Reporting: HTML (Liquid) templates rendered to PDF by WeasyPrint (Python binary)

# Import/Export
gem 'caxlsx'
gem 'charlock_holmes', '~> 0.7.7'
gem 'combine_pdf', '~> 1.0'
gem 'ekylibre-ofx-parser', '~> 1.2'
gem 'gpgme', '~> 2.0'
gem 'holidays' # Deal with statutory and other holidays
gem 'luhn', '~> 1.0'
gem 'marcel', '~> 1.0'
gem 'nokogiri', '~> 1.8'
gem 'prawn', '~> 2.4'
gem 'prawn-table'
gem 'rodf', '~> 1.0'
gem 'roo', '~> 2.8'
gem 'rubyzip', '~> 2.3'
gem 'sepa_king', '~> 0.12.0'
gem 'xml_errors_parser', github: 'ekylibre/xsd_errors_parser', branch: 'main'

# Web services
gem 'faraday', '~> 2.5'
gem 'google-cloud-bigquery'
gem 'mechanize', '~> 2.7'
gem 'rubyntlm', '>= 0.3.2'
gem 'savon', '2.12'
gem 'stripe'

# Using git until we have a proper release system for cartography
gem 'cartography', github: 'ekylibre/cartography', branch: 'eky'

# Used to convert markdown to html
gem 'gitlab_kramdown', '~> 0.6'

# for loading lexicon 5 in test mode
gem 'lexicon-common', '~> 0.2.0'

# Gems removed from the Ruby standard library
gem 'rss'



# Application server
gem 'puma', '~> 6.4'

group :development do
  gem 'bullet', '~> 7.0'

  gem 'better_errors', '~> 2.9'
  gem 'rack-mini-profiler'
  # Get the time of a process
  gem 'ruby-prof', '~> 1.4'

  # Code metrics
  gem 'haml_lint', '0.40.0', require: false
  gem 'rails_best_practices', '~> 1.20', require: false
  gem 'rubocop', '1.11.0', require: false
  gem 'rubocop-ast', '1.15.0', require: false

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 4.2'

  gem 'letter_opener', '~> 1.7'
end

group :development, :test do
  # Used by better_errors and test/lib PseudoEnvironment
  gem 'binding_of_caller', '~> 1.0'

  gem 'dotenv', '~> 2.7'

  gem 'pry', '~> 0.14'
  gem 'debug', '>= 1.9', require: false
  gem 'pry-rails', '~> 0.3.11'

  # gem 'listen', '>= 3.0.5', '< 3.2' See config/environments/development.rb:68

  # For git manipulation in test:git task
  gem 'git', '~> 1.8'

  gem 'yard', '~> 0.9.26'
end

group :test do
  # Freeze time for demo and/or tests
  gem 'timecop', '~> 0.9'

  gem 'shoulda-context', '~> 2.0'

  gem 'database_cleaner-active_record', '~> 2.0'

  gem 'minitest', "~> 5.17.0"
  gem 'minitest-reporters', '~> 1.4'

  gem 'factory_bot', '< 5'

  gem 'pdf-reader', '~> 2.4'

  gem 'simplecov', '~> 0.21.2'
  gem 'simplecov-cobertura', '~> 2.1.0'

  gem 'rails-controller-testing', '~> 1.0'

  gem 'vcr', '~> 6.2'
  gem 'webmock', '~> 3.23'
end

# Load Gemfile.local, Gemfile.plugins, plugins', and custom Gemfiles
gemfiles = Dir.glob(File.expand_path('../{plugins/*/Gemfile,Gemfile.*}', __FILE__)).keep_if{|e| e !~/(.lock)$/}
gemfiles << ENV['CUSTOM_PLUGIN_GEMFILE'] unless ENV['CUSTOM_PLUGIN_GEMFILE'].nil?
gemfiles.each do |file|
  next unless File.readable?(file)

  eval_gemfile(file)
end
