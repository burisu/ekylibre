# frozen_string_literal: true

# The lexicon-common gem uses Zeitwerk without ignoring its version file
# (which defines Lexicon::Common::VERSION, not Lexicon::Common::Version).
# Rails 7.0 eager loads gem loaders too, so this file must be ignored.
# TODO: remove with Rails 7.1 (it only eager loads the application loaders).
Zeitwerk::Registry.loaders.each do |loader|
  loader.dirs.each do |dir|
    version_file = File.join(dir, 'lexicon', 'common', 'version.rb')
    loader.ignore(version_file) if File.exist?(version_file)
  end
end

# Exchangers are registered when loaded: forget stale classes on code reload
Rails.application.reloader.to_prepare do
  ActiveExchanger::Base.reset_exchangers!
end
