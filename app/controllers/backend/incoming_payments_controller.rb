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
  class IncomingPaymentsController < Backend::BaseController
    manage_restfully(
      to_bank_at: -> { Time.zone.today },
      paid_at: -> { Time.zone.today },
      responsible_id: -> { current_user.id },
      received: true,
      mode_id: -> { params[:mode_id] ? params[:mode_id] : (payer = Entity.find_by(id: params[:entity_id].to_i)) ? payer.incoming_payments.reorder(id: :desc).first.mode_id : nil },
      t3e: {
        payer: ->(record) { record.payer.full_name },
        entity: ->(record) { record.payer.full_name },
        number: ->(record) { record.number }
      }
    )

    unroll :number, :to_bank_at, :amount, :currency, mode: :name, payer: :full_name

    def self.incoming_payments_conditions(_options = {})
      search1 = search_conditions(incoming_payments: %i[amount bank_check_number number bank_account_number], entities: %i[number full_name])
      lambda do
        c = instance_exec(&search1)
        if params[:paid_at].present? && params[:paid_at].to_s != 'all'
          c[0] << " AND #{IncomingPayment.table_name}.paid_at::DATE BETWEEN ? AND ?"
          if params[:paid_at].to_s == 'interval'
            c << params[:paid_at_started_on]
            c << params[:paid_at_stopped_on]
          else
            interval = params[:paid_at].to_s.split('_')
            c << interval.first
            c << interval.second
          end
        end
        if params[:s] == 'not_received'
          c[0] += ' AND received=?'
          c << false
        elsif params[:s] == 'to_deposit_later'
          c[0] += ' AND to_bank_at > ?'
          c << Time.zone.today
        elsif params[:s] == 'to_deposit_now'
          c[0] += " AND to_bank_at <= ? AND deposit_id IS NULL AND #{IncomingPaymentMode.table_name}.with_deposit"
          c << Time.zone.now
        end
        if params[:mode_id].present?
          c[0] += " AND #{IncomingPayment.table_name}.mode_id = ?"
          c << params[:mode_id]
        end
        if params[:provider].present?
          c[0] += " AND #{IncomingPayment.table_name}.provider ->> 'vendor' = ?"
          c << params[:provider].tap { |e| e[0] = e[0].downcase }.to_s
        end
        c
      end
    end

    list(conditions: incoming_payments_conditions, joins: :payer, order: { to_bank_at: :desc }) do |t|
      t.action :edit, unless: :deposit?
      t.action :destroy
      t.column :number, url: true
      t.column :payer, url: true
      t.column :paid_at
      t.column :amount, currency: true, url: true, on_select: :sum
      t.column :mode
      t.column :bank_check_number
      t.column :to_bank_at
      t.column :received, hidden: true
      t.column :deposit, url: true
      t.column :work_name, through: :affair, label: :affair_number, url: { controller: :sale_affairs }
      t.column :bank_statement_number, through: :journal_entry, url: { controller: :bank_statements, id: ->(record) { record.journal_entry.bank_statements.first.id } }, label: :bank_statement_number
      t.column :provider_vendor, label_method: 'provider_vendor&.capitalize', hidden: true
    end
  end
end
