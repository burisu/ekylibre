# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
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
  class UnreceivedPurchaseOrdersController < Backend::BaseController
    manage_restfully planned_at: -> { Time.zone.today+2 }, redirect_to: ->(record) { { action: :show, id: record.id } },
                     except: :new, continue: [:nature_id], model_name: 'PurchaseOrder'

    def self.list_conditions
      search1 = search_conditions(purchase_order: %i[number reference_number created_at pretax_amount], entities: %i[number full_name])
      lambda do
        c = instance_exec(&search1)
        c[0] << " AND #{PurchaseOrder.table_name}.state = ?"
        c << 'opened'
        c[0] << " AND #{PurchaseOrder.table_name}.reconciliation_state = ?"
        c << 'to_reconcile'
        if params[:responsible_id].to_i > 0
          c[0] += " AND #{PurchaseOrder.table_name}.responsible_id = ?"
          c << params[:responsible_id]
        end
        c
      end
    end

    list(conditions: list_conditions, model: :purchase_order, joins: :supplier, order: { created_at: :desc, number: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :reference_number, url: true
      t.column :supplier, url: true
      t.column :created_at
      t.column :pretax_amount, currency: true, on_select: :sum, hidden: true
    end
  end
end
