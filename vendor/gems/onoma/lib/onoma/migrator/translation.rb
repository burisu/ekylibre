module Onoma
  module Migrator
    class Translation
      class << self
        def run(migration)
          puts "Migration #{migration.name}"
          I18n.available_locales.each do |locale|
            file = Onoma.root.join('config', 'locales', "#{locale.to_s}.yml")
            hash = yaml_to_hash(file)
            migration.each_action do |action|
              ref = hash[locale.to_sym][:nomenclatures]
              ref[action.nomenclature.to_sym] ||= {}
              ref[action.nomenclature.to_sym][:items] ||= {}
              if action.is_a?(Onoma::Migration::Actions::ItemChange) && action.new_name?
                ref[action.nomenclature.to_sym][:items][action.new_name.to_sym] ||= ref[action.nomenclature.to_sym][:items].delete(action.name.to_sym)
              elsif action.is_a?(Onoma::Migration::Actions::ItemMerging)
                # ref[action.nomenclature.to_sym][:items][action.into.to_sym] ||= ref[action.nomenclature.to_sym][:items].delete(action.name.to_sym)
                ref[action.nomenclature.to_sym][:items].delete(action.name.to_sym)
              elsif action.is_a?(Onoma::Migration::Actions::NomenclatureChange) && action.changes[:name]
                ref[action.changes[:name].to_sym] = ref.delete(action.nomenclature.to_sym)
              elsif action.is_a?(Onoma::Migration::Actions::NomenclatureRemoval)
                ref.delete(action.nomenclature.to_sym)
              elsif !action.is_a?(Onoma::Migration::Actions::Base)
                raise "Cannot handle: #{action.inspect}"
              end
              File.write(file, hash_to_yaml(hash))
            end
          end
        end

        private

          def yaml_to_hash(filename)
            hash = YAML.safe_load(IO.read(filename).gsub(/^(\s*)(no|yes|false|true):(.*)$/, '\1__\2__:\3'), [], [], true)
            hash.deep_symbolize_keys
          end

          def hash_to_yaml(hash, depth = nil)
            code = hash.sort_by { |a| a[0].to_s.tr('_', ' ').strip }.map do |k, v|
              next unless v

              pair_to_yaml(k, v)
            end.join("\n")
            code = "\n" + code.indent(depth).gsub(/^\s+$/, '') unless depth.nil?
            code
          end

          def value_to_yaml(value)
            if value.is_a?(Array)
              '[' + value.map { |x| value_to_yaml(x) }.join(', ') + ']'
            elsif value.is_a?(Symbol)
              ':' + value.to_s
            elsif value.is_a?(Hash)
              hash_to_yaml(value)
            elsif value.is_a?(Numeric)
              value.to_s
            else
              v = value.to_s.gsub('\\u00A0', '\\_')
              value =~ /\n/ ? "|\n" + v.strip.indent : '"' + v + '"'
            end
          end

          def pair_to_yaml(k, v)
            if v.is_a?(Hash)
              k.to_s + ":\n" + indent(hash_to_yaml(v))
            else
              k.to_s + ': ' + value_to_yaml(v)
            end
          end

          def indent(string, depth = 1)
            string.gsub(/^/, '  ' * depth)
          end
      end
    end
  end
end
