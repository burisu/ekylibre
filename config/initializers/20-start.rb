# Load all libs contained in lib/
require 'userstamp'
require 'migration_helper'

# Data types and core ext
require 'delay'
ActiveRecord::Base.send(:extend, Delay::Validation::ClassMethods)

require 'safe_string'

# ActionIntegration

# ActiveThing

# App-specific libs
require 'ekylibre'
Rails.application.deprecators[:ekylibre] = Ekylibre.deprecator
require 'clients'

require 'working_set'

# XML definitions
autoload :Onoma,     'onoma'
# autoload :Procedo,   'procedo'
# require 'nomen'
# require 'aggeratio'
# require 'procedo'

# Measure
require 'measure'
class ::Numeric
  Measure.units.each do |unit|
    define_method "in_#{unit}".to_sym do
      Measure.new(self, unit)
    end
  end

  def in(unit)
    Measure.new(self, unit)
  end
end

# autoload :Calculus, 'calculus'

# Other things...
require 'reporting'
require 'enumerize/xml'
require 'state_machine/i18n'

require 'open_weather_map' if Onoma[:indicators]


Ekylibre.load_integrations

Ekylibre::Plugin.load unless ENV['PLUGIN'] == 'false' || ENV['RAILS_ENV'] == 'test'
Ekylibre::Plugin.plug

Aggeratio.load_path += Dir.glob(Rails.root.join('config', 'aggregators', '**', '*.xml'))
Aggeratio.load

# Map and co
Map::Layer.load

Zip.write_zip64_support = true
