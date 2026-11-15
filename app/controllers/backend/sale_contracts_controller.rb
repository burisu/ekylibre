# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class SaleContractsController < Backend::BaseController
    manage_restfully currency: -> { Preference[:currency] }

    unroll

    # params:
    #   :q Text search
    #   :state State search
    #   :period Two dates with "_" separator
    def self.conditions
      search1 = search_conditions(contracts: %i[pretax_amount number], entities: %i[number full_name])
      lambda do
        c = instance_exec(&search1)
        if params[:responsible_id].to_i > 0
          c[0] += " AND #{SaleContract.table_name}.responsible_id = ?"
          c << params[:responsible_id]
        end
        c
      end
    end

    list(conditions: conditions, joins: :client, order: { created_at: :desc, number: :desc }) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :created_at
      t.column :started_on
      t.column :stopped_on, hidden: true
      t.column :client, url: true
      t.column :responsible, url: true, hidden: true
      t.column :dayleft, hidden: true
      t.column :sale_opportunity, url: true
      t.column :pretax_amount, currency: true
    end

    list(:items, model: :sale_contract_items, conditions: { sale_contract_id: -> { params[:id] } }) do |t|
      t.column :variant, url: true
      t.column :quantity
      t.column :quantity_unit
      t.column :unit_pretax_amount, currency: true
      t.column :pretax_amount, currency: true
      t.column :forecast_duration
      t.column :real_duration
    end

    list(:projects, conditions: { sale_contract_id: -> { params[:id] } }) do |t|
      t.column :name, url: true
      t.column :responsible
      t.column :started_on
      t.column :stopped_on
      t.column :forecast_duration
      t.column :real_duration
    end
  end
end
