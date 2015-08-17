module Nomen
  XMLNS = 'http://www.ekylibre.org/XML/2013/nomenclatures'.freeze
  NS_SEPARATOR = '-'
  PROPERTY_TYPES = [:boolean, :item, :item_list, :choice, :choice_list, :string_list, :date, :decimal, :integer, :nomenclature, :string, :symbol]

  class MissingNomenclature < StandardError
  end

  class MissingChoices < StandardError
  end

  class InvalidPropertyNature < StandardError
  end

  class InvalidProperty < StandardError
  end

  autoload :Item,                'nomen/item'
  autoload :Migration,           'nomen/migration'
  autoload :Migrator,            'nomen/migrator'
  autoload :Nomenclature,        'nomen/nomenclature'
  autoload :NomenclatureSet,     'nomen/nomenclature_set'
  autoload :PropertyNature,      'nomen/property_nature'
  autoload :Reference,           'nomen/reference'
  autoload :Reflection,          'nomen/reflection'

  class << self
    def migrations_path
      Rails.root.join('db', 'nomenclatures', 'migrate')
    end

    def reference_path
      Rails.root.join('db', 'nomenclatures.xml')
    end

    # Returns version of DB
    def reference_version
      return 0 unless reference_path.exist?
      reference_document.root['version'].to_i
    end

    def reference_document
      f = File.open(reference_path, 'rb')
      document = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks.noent
      end
      f.close
      document
    end

    # Returns list of Nomen::Migration
    def migrations
      Dir.glob(migrations_path.join('*.xml')).sort.collect do |f|
        Nomen::Migration::Base.parse(Pathname.new(f))
      end
    end

    # Returns list of migrations since last done
    def missing_migrations
      last_version = reference_version
      migrations.select do |m|
        m.number > last_version
      end
    end

    # Returns the names of the nomenclatures
    def names
      @@set.nomenclature_names
    end

    def all
      @@set.nomenclatures
    end

    # Give access to named nomenclatures
    def [](name)
      @@set[name]
    end

    # Give access to named nomenclatures
    def find(name)
      @@set[name] || Nomenclature.new(name, set: @@set)
    end

    # Browse all nomenclatures
    def each(&block)
      @@set.each(&block)
    end

    def load
      if reference_path.exist?
        @@set = NomenclatureSet.load_file(reference_path)
      else
        @@set = NomenclatureSet.new
      end
    end

    # Returns the matching nomenclature
    def const_missing(name)
      n = name.to_s.underscore.pluralize
      return self[n] if @@set.exist?(n)
      super
    end
  end
end

Nomen.load
Rails.logger.info 'Loaded nomenclatures: ' + Nomen.names.to_sentence
