class AddResponsibleOnParcels < ActiveRecord::Migration[4.2]
  def change
    change_table :parcels do |t|
      t.references(:responsible, index: true)
    end
  end
end
