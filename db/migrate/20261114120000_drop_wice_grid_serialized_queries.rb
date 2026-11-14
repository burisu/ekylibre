# frozen_string_literal: true

# wice_grid has been replaced by a simple in-app grid helper
class DropWiceGridSerializedQueries < ActiveRecord::Migration[5.2]
  def up
    drop_table :wice_grid_serialized_queries, if_exists: true
  end

  def down
    create_table :wice_grid_serialized_queries do |t|
      t.string :name
      t.string :grid_name
      t.text :query
      t.timestamps
    end
    add_index :wice_grid_serialized_queries, :grid_name
    add_index :wice_grid_serialized_queries, %i[grid_name id]
  end
end
