module Backend
  # Abstract controller to manage all outgoing payments.
  # CAUTION: No routes must use this controller.
  class OutgoingPaymentsController < Backend::BaseController
    manage_restfully(
      to_bank_at: -> { Time.zone.today },
      paid_at: -> { Time.zone.today },
      responsible_id: -> { current_user.id },
      amount: -> { params[:amount].to_f },
      delivered: true,
      subclass_inheritance: true,
      t3e: {
        payee: :payee_full_name
      }
    )

    unroll :amount, :to_bank_at, :bank_check_number, :number, :currency, mode: :name, payee: :full_name
  end
end
