# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier, David Joulin
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
  class LoansController < Backend::BaseController
    manage_restfully

    unroll

    before_action :save_search_preference, only: :index

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    def self.list_conditions
      search1 = search_conditions(loans: %i[name amount], cashes: [:bank_name])
      lambda do
        c = instance_exec(&search1)
        if params[:period].present? && params[:period].to_s != 'all'
          c[0] << " AND #{Loan.table_name}.started_on BETWEEN ? AND ?"
          if params[:period].to_s == 'interval'
            c << params[:started_on]
            c << params[:stopped_on]
          else
            interval = params[:period].to_s.split('_')
            c << interval.first
            c << interval.second
          end
        end
        unless params[:state].blank?
          c[0] << " AND #{Loan.table_name}.state IN (?)"
          c << params[:state]
        end
        if params[:repayment_period].present?
          c[0] << " AND #{Loan.table_name}.repayment_period IN (?)"
          c << params[:repayment_period]
        end
        if params[:cash_id].to_i > 0
          c[0] += " AND #{Loan.table_name}.cash_id = ?"
          c << params[:cash_id]
        end
        c
      end
    end

    list(conditions: list_conditions) do |t|
      t.action :edit, if: :editable?
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :amount, currency: true
      t.column :cash, url: true
      t.status
      t.column :activity, url: true
      t.column :state, hidden: true
      t.column :started_on
      t.column :repayment_duration
      t.column :repayment_period
      t.column :shift_duration, hidden: true
      t.column :journal_entry, url: true, hidden: true
    end

    list :repayments, model: :loan_repayments, conditions: { loan_id: -> { params[:id] } } do |t|
      t.action :edit, if: :updateable?
      t.column :position
      t.column :accountable
      t.column :locked
      t.column :due_on
      t.column :amount, currency: true
      t.column :base_amount, currency: true
      t.column :interest_amount, currency: true
      t.column :insurance_amount, currency: true
      t.column :remaining_amount, currency: true
      t.column :journal_entry, url: true, hidden: true
    end

    # Show a list of loans
    def index
      @loans = Loan.reorder(:started_on).all
      # passing a parameter to Jasper for company full name and id
      @entity_of_company_full_name = Entity.of_company.full_name
      @entity_of_company_id = Entity.of_company.id

      if params[:period] == 'interval'
        @started_on = params[:started_on]
        @stopped_on = params[:stopped_on]
      elsif params[:period].present? && params[:period] != 'all'
        @started_on, @stopped_on = params[:period].split('_')
      end

      @started_on ||= FinancialYear.reorder(:started_on).first.started_on.to_s
      @stopped_on ||= FinancialYear.reorder(:started_on).last.stopped_on.to_s

      respond_to do |format|
        format.html
        format.pdf {
          return unless (template = find_and_check :document_template, params[:template])

          PrinterJob.perform_later('Printers::LoanRegistryPrinter', started_on: @started_on, stopped_on: @stopped_on, template: template, perform_as: current_user)
          notify_success(:document_in_preparation)
          redirect_to backend_loans_path
        }
      end
    end

    def confirm
      return unless (record = find_and_check)

      l = Loan::Transitions::Confirm.new(record, ongoing_at: Time.zone.now, current_user: current_user)
      if l.can_run?
        l.transition
      else
        notify_error :error_during_transition
      end
      redirect_to action: :show, id: record.id
    end

    def repay
      return unless (record = find_and_check)

      record.repay(repaid_at: Time.zone.now, current_user: current_user)

      redirect_to action: :show, id: record.id
    end

    def bookkeep
      begin
        bookkeep_until = Date.parse(params[:until])
      rescue
        notify_error(:the_bookkeep_date_format_is_invalid)
        return redirect_to(params[:redirect] || { action: :index })
      end

      count = Loan.bookkeep_repayments(until: bookkeep_until)
      notify_success(:x_loan_repayments_have_been_bookkept_successfully, count: count)

      redirect_to(params[:redirect] || { action: :index })
    end
  end
end
