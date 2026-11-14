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
  class MattersController < Backend::ProductsController
    before_action :save_search_preference, only: :index

    def self.matters_conditions
      search1 = search_conditions(products: %i[name work_number identification_number number description uuid], product_nature_variants: [:name])
      lambda do
        c = instance_exec(&search1)
        if params[:s].nil?
          params[:s] = 'available'
        end
        c[0] << " AND #{ProductNatureVariant.table_name}.type like ?"
        c << '%Variants::Article%'
        c[0] << " AND #{ProductNatureVariant.table_name}.active = ?"
        c << 't'
        if params[:label_id].to_i > 0
          c[0] << " AND #{Product.table_name}.id IN (SELECT product_id FROM product_labellings WHERE label_id IN (?))"
          c << params[:label_id].to_i
        end
        if params[:s] == 'available'
          c[0] << " AND #{Product.table_name}.dead_at IS NULL"
        elsif params[:s] == 'consume'
          c[0] << " AND #{Product.table_name}.dead_at IS NOT NULL"
        end
        if params[:s] == 'available'
          c[0] << " AND #{Product.table_name}.id IN (SELECT product_populations.product_id FROM product_populations INNER JOIN (SELECT product_id, MAX(started_at) as started_at FROM product_populations GROUP BY product_id) last_population ON product_populations.product_id = last_population.product_id and product_populations.started_at = last_population.started_at WHERE value > 0)"
        end
        if params[:sub_nature_id].present?
          if params[:sub_nature_id] == 'Other'
            c[0] << " AND #{ProductNatureVariant.table_name}.type =? "
            c << 'Variants::ArticleVariant'
          else
            c[0] << " AND #{ProductNatureVariant.table_name}.type =? "
            c << 'Variants::Articles::'+ params[:sub_nature_id].to_s + 'Article'
          end
        end
        if params[:period].to_s != 'all'
          started_on = params[:started_on]
          stopped_on = params[:stopped_on]
          c[0] << " AND #{Product.table_name}.born_at::DATE BETWEEN ? AND ?"
          c << started_on
          c << stopped_on
          if params[:s] == 'consume'
            c[0] << " AND #{Product.table_name}.dead_at::DATE BETWEEN ? AND ?"
            c << started_on
            c << stopped_on
          end
        end
        c
      end
    end

    list(conditions: matters_conditions, selectable: true, join: :variant, distinct: true, order: { born_at: :desc }) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :born_at, type: :date
      t.column :work_number
      t.column :identification_number, hidden: true
      t.column :name, url: true
      t.column :variant, url: { controller: ->(record) { record.variant.class.name.tableize }, namespace: :backend }
      t.column :variety
      t.column :population
      t.column :conditioning_unit
      t.column :container, url: true
      t.column :description, hidden: true
      t.column :derivative_of
    end

  end
end
