module Onoma
  module Migrator
    class << self
      def migrate
        Onoma.missing_migrations.each do |migration|
          puts migration.name
          Onoma::Migrator::Reference.run(migration)
          Onoma::Migrator::Translation.run(migration)
        end
      end
    end
  end
end
