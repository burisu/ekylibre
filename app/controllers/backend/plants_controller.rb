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
  class PlantsController < Backend::MattersController
    include InspectionViewable

    def self.list_conditions
      search1 = search_conditions(products: %i[name work_number])
      lambda do
        c = instance_exec(&search1)
        if params[:born_at].present? && params[:born_at].to_s != 'all'
          c[0] << " AND #{Plant.table_name}.born_at::DATE BETWEEN ? AND ?"
          if params[:born_at].to_s == 'interval'
            c << params[:born_at_started_on]
            c << params[:born_at_stopped_on]
          else
            interval = params[:born_at].to_s.split('_')
            c << interval.first
            c << interval.second
          end
        end
        if params[:dead_at].present? && params[:dead_at].to_s != 'all'
          c[0] << " AND #{Plant.table_name}.dead_at::DATE BETWEEN ? AND ?"
          if params[:dead_at].to_s == 'interval'
            c << params[:dead_at_started_on]
            c << params[:dead_at_stopped_on]
          else
            interval = params[:dead_at].to_s.split('_')
            c << interval.first
            c << interval.second
          end
        end
        if params[:variety].present?
          c[0] << " AND #{Plant.table_name}.variety = ?"
          c << params[:variety]
        end
        if params[:area].present?
          interval = params[:area].split(',')
          c[0] << " AND (SELECT (ST_Area(ST_Transform(ST_GeomFromEWKB(#{Plant.table_name}.initial_shape),2154))) BETWEEN ? AND ?)"
          c << interval.first.to_i * 10_000
          c << interval.last.to_i * 10_000
        end
        c
      end
    end

    list(conditions: list_conditions) do |t|
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :work_number
      t.column :variety
      t.column :work_name, through: :container, url: true
      t.column :net_surface_area, datatype: :measure
      t.status
      t.column :human_status, label: :state, hidden: true
      t.column :human_quantity_during_last_sowing, label: :quantity_during_sowing, hidden: true
      t.column :born_at
      t.column :dead_at
    end

    list :plant_countings, conditions: { plant_id: -> { params[:id] } } do |t|
      t.column :number, url: true
      t.status label: :state
      t.column :read_at, label: :date
    end

    def index
      notify_plant_creation_warning

      super
    end

    def show
      return unless plant = find_and_check

      harvest_advisor = ::Interventions::Phytosanitary::PhytoHarvestAdvisor.new
      @harvest_possible = harvest_advisor.harvest_possible?(plant, Time.zone.now)
      @reentry_possible = harvest_advisor.reentry_possible?(plant, Time.zone.now)
      super
    end

    private

      def notify_plant_creation_warning
        warnings = []
        if LandParcel.count.zero?
          warnings << helpers.link_to(:a_land_parcel.tl, backend_land_parcels_path)
        end

        if !Matter.any?{|matter| matter.nature.variety == 'seed' || matter.nature.variety == 'plant' }
          warnings << helpers.link_to(:seeds_or_plants_stock.tl, backend_matters_path)
        end

        if warnings.any?
          notify_warning_now(:before_add_a_plant_add_a_x_html, x: as_list(warnings), html: true)
        end
      end

      # @param [Array<String>] elements
      # @return [String] HTML representation of a list that contains all the elements in `elements`
      def as_list(elements)
        helpers.content_tag(:ul) do
          elements.map do |element|
            helpers.content_tag(:li, element)
          end.join.html_safe
        end
      end
  end
end
