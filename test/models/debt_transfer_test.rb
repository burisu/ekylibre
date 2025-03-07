# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: debt_transfers
#
#  accounted_at            :datetime
#  affair_id               :integer          not null
#  amount                  :decimal(19, 4)   default(0.0)
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string           not null
#  debt_transfer_affair_id :integer          not null
#  id                      :integer          not null, primary key
#  journal_entry_id        :integer
#  lock_version            :integer          default(0), not null
#  nature                  :string           not null
#  number                  :string
#  updated_at              :datetime         not null
#  updater_id              :integer
#
require 'test_helper'

class DebtTransferTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'debt transfer from purchase affair to sale affair' do
    # sale_amount, purchase_amount, transferred, sale_remaining, purchase_remaining
    cases = [
      [1000, 500, 500.0, -500.0, 0.0],
      [500, 1000, 500.0, 0.0, 500.0]
    ]

    cases.each do |(sale_amount, purchase_amount, transferred, sale_remaining, purchase_remaining)|
      exec_test_debt_transfer(sale_amount, purchase_amount, transferred, sale_remaining, purchase_remaining)
    end
  end

  private

    def exec_test_debt_transfer(sale_amount, purchase_amount, transferred, sale_remaining, purchase_remaining)
      variants = ProductNatureVariant.where(nature: ProductNature.where(population_counting: :decimal))
      options = {
        name: '0% VAT',
        amount: 0,
        nature: :null_vat,
        collect_account: Account.find_or_create_by_number('4566'),
        deduction_account: Account.find_or_create_by_number('4567'),
        country: :fr
      }
      tax = Tax.create_with(options).find_or_create_by!(name: '0% VAT')

      ### sale
      sale_nature = SaleNature.first
      sale = Sale.new(nature: sale_nature, client: Entity.normal.first, invoiced_at: DateTime.new(2018, 1, 1))
      sale.items.new(variant: variants.first,
                     conditioning_quantity: 2,
                     pretax_amount: sale_amount,
                     tax: tax,
                     conditioning_unit: variants.first.guess_conditioning[:unit],
                     compute_from: 'pretax_amount')
      sale.save!
      sale.invoice

      ### purchase
      purchase_nature = PurchaseNature.first
      purchase = PurchaseInvoice.create!(nature: purchase_nature, supplier: Entity.normal.first, invoiced_at: DateTime.new(2018, 1, 1))
      purchase.items.create!(variant: variants.first,
                             conditioning_quantity: 1,
                             unit_pretax_amount: purchase_amount,
                             conditioning_unit: variants.first.guess_conditioning[:unit],
                             tax: tax)

      # just to avoid false negative
      assert_equal purchase.items.first.amount, purchase_amount, "can't run debt transfer test without a valid purchase"

      count = DebtTransfer.count

      dt, dt2 = DebtTransfer.create_and_reflect!(affair: sale.affair, debt_transfer_affair: purchase.affair, accounted_at: DateTime.new(2018, 1, 2))

      assert_equal count + 2, DebtTransfer.count, 'Two debt transfers should be created. Got: ' + (DebtTransfer.count - count).to_s

      assert_equal 'sale_regularization', dt.nature.to_s
      assert_equal 'purchase_regularization', dt2.nature.to_s

      assert_equal transferred, dt.amount.to_f
      assert_equal transferred, dt2.amount.to_f

      assert_equal sale.affair, dt.affair
      assert_equal purchase.affair, dt.debt_transfer_affair
      assert_equal purchase.affair, dt2.affair
      assert_equal sale.affair, dt2.debt_transfer_affair

      assert_not_nil dt.journal_entry
      assert_not_nil dt2.journal_entry

      assert_equal transferred, dt.journal_entry.debit.to_f
      assert_equal transferred, dt.journal_entry.credit.to_f

      assert_equal purchase_remaining, dt.debt_transfer_affair.balance.to_f
      assert_equal sale_remaining, dt.affair.balance.to_f

      dt.destroy!

      assert_equal count, DebtTransfer.count, 'Two debt transfers should be destroyed. Got: ' + (DebtTransfer.count - count).to_s
    end
end
