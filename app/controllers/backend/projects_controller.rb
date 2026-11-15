module Backend
  class ProjectsController < Backend::BaseController
    manage_restfully

    unroll

    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :variant_id
    def self.list_conditions
      search1 = search_conditions(projects: %i[name comment])
      lambda do
        c = instance_exec(&search1)
        if params[:team_id].to_i > 0
          c[0] << " AND #{Team.table_name}.id = ?"
          c << params[:team_id].to_i
        end
        c
      end
    end

    list(conditions: list_conditions, joins: %i[team]) do |t|
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :work_number
      t.column :nature
      t.column :responsible, url: true
      t.column :activity, url: true
      t.column :team, url: true
      t.column :started_on
      t.column :stopped_on
      t.column :forecast_duration
      t.column :real_duration
      t.column :closed
    end

    list :tasks, model: :project_tasks, conditions: { project_id: -> { params[:id] } } do |t|
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :work_number
      t.column :name, url: true
      t.column :responsible, url: true
      t.column :started_on
      t.column :stopped_on
      t.column :forecast_duration
      t.column :forecast_duration_unit
      t.column :real_duration
      t.column :sale_contract_item # , on_select: :sum
      t.column :billing_method, hidden: true
      # t.column :sale_contract_item, index: true, hidden: true
    end
  end
end
