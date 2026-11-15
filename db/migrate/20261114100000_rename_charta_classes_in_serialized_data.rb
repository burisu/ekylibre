# frozen_string_literal: true

# The charta gem has been replaced by the in-app Geo module. Geometries
# serialized with their Ruby class name must be renamed.
class RenameChartaClassesInSerializedData < ActiveRecord::Migration[5.2]
  def up
    %w[item_object item_changes].each do |column|
      execute <<~SQL
        UPDATE versions
           SET #{column} = replace(#{column}, '!ruby/object:Charta::', '!ruby/object:Geo::')
         WHERE #{column} LIKE '%!ruby/object:Charta::%'
      SQL
    end
    execute <<~SQL
      UPDATE products
         SET reading_cache = replace(reading_cache::text, '"Charta::', '"Geo::')::jsonb
       WHERE reading_cache::text LIKE '%"Charta::%'
    SQL
  end

  def down
    %w[item_object item_changes].each do |column|
      execute <<~SQL
        UPDATE versions
           SET #{column} = replace(#{column}, '!ruby/object:Geo::', '!ruby/object:Charta::')
         WHERE #{column} LIKE '%!ruby/object:Geo::%'
      SQL
    end
    execute <<~SQL
      UPDATE products
         SET reading_cache = replace(reading_cache::text, '"Geo::', '"Charta::')::jsonb
       WHERE reading_cache::text LIKE '%"Geo::%'
    SQL
  end
end
