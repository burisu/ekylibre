module Backend
  class PurchasePaymentsController < Backend::OutgoingPaymentsController
    manage_restfully(
      to_bank_at: -> { Time.zone.today },
      paid_at: -> { Time.zone.today },
      responsible_id: -> { current_user.id },
      mode_id: -> { params[:mode_id] ? params[:mode_id] : (payer = Entity.find_by(id: params[:payee_id].to_i)) ? payer.outcoming_payments.reorder(id: :desc).first&.mode_id : nil },
      t3e: {
        payee: ->(record) { record&.payee&.full_name }
      }
    )

    def self.list_conditions
      search1 = search_conditions(outgoing_payments: %i[amount bank_check_number number], entities: %i[number full_name])
      lambda do
        c = instance_exec(&search1)
        if params[:s] == 'not_delivered'
          c[0] += ' AND delivered = ?'
          c << false
        end
        c
      end
    end

    list(conditions: list_conditions, joins: :payee, order: { to_bank_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :payee, url: true
      t.column :paid_at
      t.column :amount, currency: true, url: true, on_select: :sum
      t.column :mode
      t.column :bank_check_number
      t.column :to_bank_at
      t.column :delivered, hidden: true
      t.column :work_name, through: :affair, label: :affair_number, url: { controller: :purchase_affairs }
      t.column :deal_work_name, through: :affair, label: :purchase_number, url: { controller: :purchase_invoices, id: ->(record) { record.affair.deals_of_type(Purchase).first.id } }
      t.column :bank_statement_number, through: :journal_entry, url: { controller: :bank_statements, id: ->(record) { record.journal_entry.bank_statements.first.id } }, label: :bank_statement_number
    end
  end
end
