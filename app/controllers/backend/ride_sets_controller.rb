module Backend
  class RideSetsController < Backend::BaseController
    manage_restfully

    unroll

    def self.list_conditions
      search1 = search_conditions(ride_sets: %i[number])
      lambda do
        c = instance_exec(&search1)
        if params[:period].present? && params[:period].to_s != 'all'
          c[0] << " AND #{RideSet.table_name}.started_at::DATE BETWEEN ? AND ?"
          if params[:period].to_s == 'interval'
            c << params[:started_on]
            c << params[:stopped_on]
          else
            interval = params[:period].to_s.split('_')
            c << interval.first
            c << interval.second
          end
        end
        if params[:equipment_id].to_i > 0
          c[0] += " AND #{RideSet.table_name}.id IN (SELECT DISTINCT ride_set_id FROM #{RideSetEquipment.table_name} WHERE product_id = ?)"
          c << params[:equipment_id]
        end
        c
      end
    end

    list(conditions: list_conditions, selectable: true, order: { started_at: :desc }) do |t|
      t.column :number, url: true
      t.column :nature
      t.column :state, label_method: :decorated_state
      t.column :created_at
      t.column :started_at
      t.column :stopped_at
      t.column :duration, label_method: :decorated_duration
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration, label_method: :decorated_sleep_duration
      t.column :road, class: 'center'
      t.column :main_equipment, url: { controller: 'backend/equipments', id: ->(record) { record.equipments.of_nature('main').first.product_id } }
      t.column :additional_tool_one, url: { controller: 'backend/equipments', id: ->(record) { record.equipments.of_nature('additional')[0].product_id } }, hidden: :additional_tool_one.nil?
      t.column :additional_tool_two, url: { controller: 'backend/equipments', id: ->(record) { record.equipments.of_nature('additional')[1].product_id } }, hidden: :additional_tool_two.nil?
      t.column :provider_vendor
    end

    list(:rides, selectable: true, model: :ride, conditions: { ride_set_id: -> { params[:id] } }, order: 'rides.started_at DESC',
line_class: ->(record) { record.state }) do |t|
      t.column :number, url: true, class: 'ride-title'
      t.column :intervention, url: true
      t.column :nature
      t.column :started_at
      t.column :stopped_at
      t.column :duration, label_method: :decorated_duration
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration, label_method: :decorated_sleep_duration
      t.column :main_equipment, url: { controller: 'backend/equipments', id: ->(record) { record.ride_set.equipments.of_nature('main').first.product_id } }
      t.column :additional_tool_one, url: { controller: 'backend/equipments', id: ->(record) { record.ride_set.equipments.of_nature('additional')[0].product_id } }, hidden: :additional_tool_one.nil?
      t.column :additional_tool_two, url: { controller: 'backend/equipments', id: ->(record) { record.ride_set.equipments.of_nature('additional')[1].product_id } }, hidden: :additional_tool_two.nil?
      t.column :provider_vendor, label_method: :provider_vendor
    end

    def index
      notify_ride_set_information

      if params[:ride_set_job_notify]
        notify_now(params[:ride_set_job_notify])
      end

      super
    end

    private

      def notify_ride_set_information
        if Integration.where(nature: %w[samsys traccar]).count.zero?
          notify_warning_now(helpers.link_to(:ride_set_no_integration.tl, backend_integrations_path))
        elsif RideSet.count.zero?
          notify_now(:ride_set_no_data.tl)
        else
          notify_now(:ride_set_to_ride_information.tl)
        end
      end
  end
end
