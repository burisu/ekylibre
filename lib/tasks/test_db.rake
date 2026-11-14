# frozen_string_literal: true

namespace :db do
  namespace :test do
    desc 'Recreate the test database from db/structure.sql (creates PostGIS extensions first)'
    task load_postgis_structure: :load_config do
      config = ActiveRecord::Base.configurations.configs_for(env_name: 'test').first.configuration_hash
      env = { 'PGPASSWORD' => config[:password].to_s, 'PGHOST' => config[:host].to_s, 'PGPORT' => config[:port].to_s, 'PGUSER' => config[:username].to_s }
      database = config[:database]
      psql = ->(db, *args) { system(env, 'psql', '--quiet', '--no-psqlrc', '--set', 'ON_ERROR_STOP=1', '-d', db, *args) || raise("psql failed on #{db}") }

      psql.call('postgres', '-c', "DROP DATABASE IF EXISTS #{database}", '-c', "CREATE DATABASE #{database}")
      psql.call(database, '-c', 'CREATE SCHEMA postgis', '-c', 'CREATE EXTENSION postgis SCHEMA postgis',
                '-c', 'CREATE EXTENSION "uuid-ossp" SCHEMA postgis', '-c', 'CREATE EXTENSION unaccent SCHEMA postgis',
                '-c', 'CREATE EXTENSION pg_trgm SCHEMA postgis')
      structure = File.read(Rails.root.join('db', 'structure.sql'))
                      .gsub(/^CREATE SCHEMA (public|postgis|lexicon);/, 'CREATE SCHEMA IF NOT EXISTS \1;')
      IO.popen(env, ['psql', '--quiet', '--no-psqlrc', '--set', 'ON_ERROR_STOP=1', '-d', database], 'w', out: File::NULL) { |io| io.write(structure) }
      raise 'Cannot load db/structure.sql' unless $?.success?

      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::InternalMetadata[:environment] = 'test'
      puts "Test database #{database} loaded from db/structure.sql"
    end
  end
end
