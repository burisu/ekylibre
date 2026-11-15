# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
# Rails < 7.1 relies on Logger being loaded (concurrent-ruby >= 1.3.5 no longer does it)
require 'logger'
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

# Filtre les warnings irreductibles (gems en conflit Ruby 2.6 stdlib + valeurs d'enum
# qui collisionnent avec des predicats d'ActiveSupport). Les autres warnings Ruby
# restent visibles.
module SilencedWarnings
  PATTERNS = [
    %r{net/protocol\.rb.*already initialized constant},
    %r{net/protocol\.rb.*previous definition},
    %r{It's not recommended to use `.+` as a field value since `.+\?` is defined}
  ].freeze

  def warn(message)
    return if PATTERNS.any? { |p| message =~ p }
    super
  end
end
Warning.singleton_class.prepend(SilencedWarnings)

if ENV['RAILS_ENV'] != 'production'
  require 'dotenv'

  Dotenv.load(Pathname.new(__dir__).join('..', '.env'))
end
