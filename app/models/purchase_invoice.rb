# frozen_string_literal: true

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
# == Table: purchases
#
#  accounted_at                             :datetime
#  affair_id                                :integer
#  amount                                   :decimal(19, 4)   default(0.0), not null
#  command_mode                             :string
#  confirmed_at                             :datetime
#  contract_id                              :integer
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  currency                                 :string           not null
#  custom_fields                            :jsonb
#  delivery_address_id                      :integer
#  description                              :text
#  estimate_reception_date                  :datetime
#  id                                       :integer          not null, primary key
#  invoiced_at                              :datetime
#  journal_entry_id                         :integer
#  lock_version                             :integer          default(0), not null
#  nature_id                                :integer
#  number                                   :string           not null
#  ordered_at                               :datetime
#  payment_at                               :datetime
#  payment_delay                            :string
#  planned_at                               :datetime
#  pretax_amount                            :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_journal_entry_id :integer
#  reconciliation_state                     :string
#  reference_number                         :string
#  responsible_id                           :integer
#  state                                    :string           not null
#  supplier_id                              :integer          not null
#  tax_payability                           :string           not null
#  type                                     :string
#  undelivered_invoice_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#
class PurchaseInvoice < Purchase
  include Versionable
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :undelivered_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :quantity_gap_on_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  has_many :journal_entries, as: :resource
  has_many :reception_items, through: :items, source: :parcels_purchase_invoice_items
  has_many :receptions, through: :reception_items
  has_many :storings, through: :reception_items
  has_many :products, through: :storings
  has_many :interventions, through: :products
  acts_as_affairable :supplier, class_name: 'PurchaseAffair'

  scope :invoiced_between, lambda { |started_at, stopped_at|
    where(invoiced_at: started_at..stopped_at)
  }

  scope :accepted_reconcile, -> { where(reconciliation_state: %w[accepted reconcile]) }
  scope :unpaid, -> { where.not(affair: Affair.closeds) }
  scope :unpaid_and_not_empty, -> { where.not(affair: Affair.closeds.where("debit != 0 OR credit != 0")) }
  scope :current, -> { unpaid }
  scope :current_or_self, ->(purchase) { where(unpaid).or(where(id: (purchase.is_a?(Purchase) ? purchase.id : purchase))) }
  scope :with_nature, ->(id) { where(nature_id: id) }

  protect allow_update_on: %w[reference_number responsible_id invoiced_at payment_delay tax_payability description payment_at updated_at] do
    items.exists? && PurchaseInvoice.unpaid_and_not_empty.where(id: self.id).empty?
  end

  before_validation(on: :create) do
    self.state = :invoice
    self.invoiced_at ||= created_at
  end

  before_validation do
    if reconciliation_state.to_s != 'accepted'
      if self.items.reject(&:marked_for_destruction?).any? { |i| i.parcels_purchase_invoice_items.present? }
        self.reconciliation_state = 'reconcile'
      else
        self.reconciliation_state = 'to_reconcile'
      end
    end
  end

  after_update do
    affair.update_attributes(third_id: third.id) if affair && affair.deals.count == 1
    affair.reload_gaps if affair
    true
  end

  validate do
    if invoiced_at
      errors.add(:invoiced_at, :before, restriction: Time.zone.now.l) if invoiced_at > Time.zone.now
    end
  end

  after_save do
    items.each do |item|
      item.create_fixed_asset if item.fixed_asset.nil?

      item.update_fixed_asset if item.fixed_asset.present? && item.saved_change_to_pretax_amount?
    end
    UpdateInterventionCostingsJob.perform_later(interventions.pluck(:id))
  end

  # This callback permits to add journal entries corresponding to the purchase order/invoice
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    # take reference_number (external ref) if exist else take number (internal ref)
    r_number = (reference_number.blank? ? number : reference_number)
    b.journal_entry(nature.journal, reference_number: r_number, printed_on: invoiced_on, if: items.any?) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human, number: number, supplier: supplier.full_name, products: (description.blank? ? items.collect(&:name).to_sentence : description.gsub(/\r?\n/, ' / ')))
      items.each do |item|
        entry.add_debit(label, item.account, item.pretax_amount, activity_budget: item.activity_budget, team: item.team, equipment: item.equipment, project_budget: item.project_budget, as: :item_product, resource: item, variant: item.variant)
        tax = item.tax
        account_id = item.fixed? ? tax.fixed_asset_deduction_account_id : nil
        account_id ||= tax.deduction_account_id # TODO: Check if it is good to do that
        if tax.intracommunity
          reverse_charge_amount = tax.compute(item.pretax_amount, intracommunity: true).round(precision)
          entry.add_debit(label, account_id, reverse_charge_amount, tax: tax, pretax_amount: item.pretax_amount, as: :item_tax, resource: item, variant: item.variant)
          entry.add_credit(label, tax.intracommunity_payable_account_id, reverse_charge_amount, tax: tax, pretax_amount: item.pretax_amount, resource: item, as: :item_tax_reverse_charge, variant: item.variant)
        else
          entry.add_debit(label, account_id, item.taxes_amount, tax: tax, pretax_amount: item.pretax_amount, as: :item_tax, resource: item, variant: item.variant)
        end
      end
      entry.add_credit(label, supplier.account(:supplier).id, amount, as: :supplier)
    end

    # For undelivered invoice
    # exchange undelivered invoice from parcel
    journal = Journal.used_for_unbilled_payables!(currency: currency)
    b.journal_entry(journal, printed_on: invoiced_on, as: :undelivered_invoice) do |entry|
      parcels.includes(undelivered_invoice_journal_entry: :items).references(undelivered_invoice_journal_entry: :items).each do |parcel|
        next unless parcel.undelivered_invoice_journal_entry

        label = tc(:exchange_undelivered_invoice, resource: parcel.class.model_name.human, number: parcel.number, entity: supplier.full_name, mode: parcel.nature.l)
        undelivered_items = parcel.undelivered_invoice_journal_entry.items
        undelivered_items.each do |undelivered_item|
          next unless undelivered_item.real_balance.nonzero?

          entry.add_credit(label, undelivered_item.account.id, undelivered_item.real_balance, resource: undelivered_item, as: :undelivered_item, variant: undelivered_item.variant)
        end
      end
    end

    # For gap between parcel item quantity and purchase item quantity
    # if more quantity on purchase than parcel then i have value in D of stock account
    journal = Journal.used_for_permanent_stock_inventory!(currency: currency)
    b.journal_entry(journal, printed_on: invoiced_on, as: :quantity_gap_on_invoice, if: items.any?) do |entry|
      label = tc(:quantity_gap_on_invoice, resource: self.class.model_name.human, number: number, entity: supplier.full_name)
      items.includes(:parcels_purchase_orders_items).references(:parcels_purchase_orders_items).each do |item|
        next unless item.variant.storable?

        parcel_items_quantity = if !item.parcels_purchase_orders_items.empty?
                                  item.parcels_purchase_orders_items.sum(:population)
                                else
                                  item.parcels_purchase_invoice_items.sum(:population)
                                end

        gap = item.quantity - parcel_items_quantity

        next unless (item.parcels_purchase_orders_items.any? && item.parcels_purchase_orders_items.first.unit_pretax_stock_amount) ||
                    (item.parcels_purchase_invoice_items.any? && item.parcels_purchase_invoice_items.first.unit_pretax_stock_amount)

        quantity = if !item.parcels_purchase_orders_items.empty?
                     item.parcels_purchase_orders_items.first.unit_pretax_stock_amount
                   else
                     item.parcels_purchase_invoice_items.first.unit_pretax_stock_amount
                   end

        gap_value = gap * quantity
        next if gap_value.zero?

        entry.add_debit(label, item.variant.stock_account_id, gap_value, resource: item, as: :stock, variant: item.variant)
        entry.add_credit(label, item.variant.stock_movement_account_id, gap_value, resource: item, as: :stock_movement, variant: item.variant)
      end
    end
  end

  def invoiced_on
    dealt_at.to_date
  end

  def dealt_at
    invoiced_at
  end

  def purchased?
    true
  end

  def payable?
    sepable? && amount != 0.0 && affair_balance != 0.0
  end

  # Save the last date when the invoice of purchase was received
  def invoice(invoiced_at = nil)
    # no more usage of state machine
    # return false unless can_invoice?
    reload
    self.invoiced_at ||= invoiced_at || Time.zone.now
    save!
  end

  def linked_to_tax_declaration?
    if journal_entry
      journal_entry.items.flat_map(&:tax_declaration_item_parts).any?
    else
      false
    end
  end

  def reconciled?
    items.any? { |item| item.parcels_purchase_invoice_items.present? }
  end

  def status
    affair.status
  end

  def human_status
    affair.human_status
  end

  def unpaid?
    PurchaseInvoice.unpaid.include?(self)
  end

  def has_attachments
    self.attachments.present?
  end

  def has_klippa_ocr_attachment
    if self.attachments.present?
      document = self.attachments.first.document
      if document.klippa_metadata.present?
        document
      else
        nil
      end
    else
      nil
    end
  end
end
