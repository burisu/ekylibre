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
  class SubscriptionsController < Backend::BaseController
    manage_restfully(
      # address_id: 'EntityAddress.find_by(entity_id: params[:subscriber_id]).id rescue nil'.c,
      # nature_id: 'SubscriptionNature.first.id rescue 0'.c,
      quantity: 1,
      started_on: -> { Time.zone.today },
      stopped_on: -> { Time.zone.today + 1.year - 1.day },
      t3e: {
        nature: ->(record) { record.nature_name },
        start: ->(record) { record.started_on.l },
        finish: ->(record) { record.stopped_on.l }
      }
    )
    unroll

    def self.subscriptions_conditions
      search1 = search_conditions(subscriptions: %i[codes description number], entities: %i[number full_name])
      lambda do
        c = instance_exec(&search1)
        unless params[:nature_id].to_i.zero?
          c[0] += " AND #{Subscription.table_name}.nature_id = ?"
          c << params[:nature_id].to_i
        end
        if params[:state].is_a?(Array) && !params[:state].empty?
          c[0] << " AND #{Subscription.table_name}.status IN (?)"
          c << params[:state]
        end
        if params[:subscribed_on].to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          c[0] += " AND ? BETWEEN #{Subscription.table_name}.started_on AND #{Subscription.table_name}.stopped_on"
          c << params[:subscribed_on]
        end
        c
      end
    end

    list(conditions: subscriptions_conditions, order: { started_on: :desc }, joins: :subscriber, line_class: ->(record) { (record.disabled? ? 'disabled' : record.active? ? 'success' : '') + (record.suspended ? 'squeezed' : '') }) do |t|
      t.action :edit
      t.action :renew, method: :post, if: ->(record) { current_user.can?(:write, :sales) && record.renewable? }
      t.action :suspend, method: :post, if: :suspendable?
      t.action :takeover, method: :post, if: :suspended
      t.action :destroy, if: :destroyable_by_user?
      t.column :number, url: true
      t.column :subscriber, url: true
      t.column :coordinate, through: :address, url: true
      t.column :default_mail_coordinate, through: :subscriber
      # t.column :product_nature
      t.column :status
      # t.column :sale, url: true
      t.column :started_on
      t.column :stopped_on
      t.column :trial_started_at
      t.column :trial_stopped_at
    end

    def renew
      @subscription = find_and_check
      unless @subscription.renewable?
        notify_error :subscription_is_not_renewable
        redirect_to params[:redirect] || { action: :show, id: @subscription.id }
        return
      end
      unless current_user.can?(:write, :sales)
        notify_error :access_denied
        redirect_to params[:redirect] || { action: :show, id: @subscription.id }
        return
      end
      redirect_to(@subscription.renew_attributes.merge(controller: :sales, action: :new))
    end

    def suspend
      @subscription = find_and_check
      @subscription.suspend
      redirect_to params[:redirect] || { action: :show, id: @subscription.id }
    end

    def takeover
      @subscription = find_and_check
      @subscription.takeover
      redirect_to params[:redirect] || { action: :show, id: @subscription.id }
    end
  end
end
