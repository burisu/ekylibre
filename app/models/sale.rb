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
# == Table: sales
#
#  accounted_at                             :datetime
#  address_id                               :integer
#  affair_id                                :integer
#  amount                                   :decimal(19, 4)   default(0.0), not null
#  annotation                               :text
#  client_id                                :integer          not null
#  client_reference                         :string
#  codes                                    :jsonb
#  conclusion                               :text
#  confirmed_at                             :datetime
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  credit                                   :boolean          default(FALSE), not null
#  credited_sale_id                         :integer
#  currency                                 :string           not null
#  custom_fields                            :jsonb
#  delivery_address_id                      :integer
#  description                              :text
#  downpayment_amount                       :decimal(19, 4)   default(0.0), not null
#  expiration_delay                         :string
#  expired_at                               :datetime
#  function_title                           :string
#  has_downpayment                          :boolean          default(FALSE), not null
#  id                                       :integer          not null, primary key
#  initial_number                           :string
#  introduction                             :text
#  invoice_address_id                       :integer
#  invoiced_at                              :datetime
#  journal_entry_id                         :integer
#  letter_format                            :boolean          default(TRUE), not null
#  lock_version                             :integer          default(0), not null
#  nature_id                                :integer
#  number                                   :string           not null
#  payment_at                               :datetime
#  payment_delay                            :string           not null
#  pretax_amount                            :decimal(19, 4)   default(0.0), not null
#  provider                                 :jsonb
#  quantity_gap_on_invoice_journal_entry_id :integer
#  reference_number                         :string
#  responsible_id                           :integer
#  state                                    :string           not null
#  subject                                  :string
#  transporter_id                           :integer
#  undelivered_invoice_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#
require 'benchmark'

class Sale < ApplicationRecord
  include Attachable
  include Customizable
  include Providable
  attr_readonly :currency
  refers_to :currency
  belongs_to :affair
  belongs_to :client, class_name: 'Entity'
  belongs_to :payer, class_name: 'Entity', foreign_key: :client_id
  belongs_to :address, class_name: 'EntityAddress'
  belongs_to :delivery_address, class_name: 'EntityAddress'
  belongs_to :invoice_address, class_name: 'EntityAddress'
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :undelivered_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :quantity_gap_on_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :nature, class_name: 'SaleNature'
  belongs_to :credited_sale, class_name: 'Sale'
  belongs_to :responsible, -> { contacts }, class_name: 'Entity'
  belongs_to :transporter, class_name: 'Entity'
  has_many :credits, class_name: 'Sale', foreign_key: :credited_sale_id
  has_many :parcels, dependent: :nullify, inverse_of: :sale, class_name: 'Shipment'
  has_many :items, -> { order('position, sale_items.id') }, class_name: 'SaleItem', dependent: :destroy, inverse_of: :sale
  has_many :journal_entries, as: :resource
  has_many :subscriptions, through: :items, class_name: 'Subscription', source: 'subscription'
  has_many :parcel_items, through: :parcels, source: :items
  has_one :client_payment_mode, through: :client
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :confirmed_at, :expired_at, :invoiced_at, :payment_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :amount, :downpayment_amount, :pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :annotation, :conclusion, :description, :introduction, length: { maximum: 500_000 }, allow_blank: true
  validates :client_reference, :expiration_delay, :function_title, :initial_number, :reference_number, :subject, length: { maximum: 500 }, allow_blank: true
  validates :credit, :has_downpayment, :letter_format, inclusion: { in: [true, false] }
  validates :client, :currency, :payer, :payment_delay, presence: true
  validates :number, presence: true, uniqueness: true, length: { maximum: 500 }
  validates :state, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :initial_number, :number, :state, length: { allow_nil: true, maximum: 60 }
  validates :client, :currency, :nature, presence: true
  validates :invoiced_at, presence: { if: :invoice? }, financial_year_writeable: true, ongoing_exchanges: true, allow_blank: true
  validates_associated :items
  validate :items_presence
  validates_delay_format_of :payment_delay, :expiration_delay

  alias_attribute :third_id, :client_id

  acts_as_numbered :number, readonly: false
  acts_as_affairable :client, debit: :credit?
  accepts_nested_attributes_for :items, allow_destroy: true

  delegate :with_accounting, to: :nature

  enumerize :payment_delay, in: ['1 week', '30 days', '30 days, end of month', '60 days', '60 days, end of month']

  scope :invoiced_between, lambda { |started_at, stopped_at|
    where(invoiced_at: started_at..stopped_at)
  }

  scope :estimate_between, lambda { |started_at, stopped_at|
    where(accounted_at: started_at..stopped_at, state: :estimate)
  }

  scope :order_between, lambda { |started_at, stopped_at|
    where(confirmed_at: started_at..stopped_at, state: :order)
  }

  scope :with_nature, ->(id) { where(nature_id: id) }

  scope :of_nature, ->(nature) { where(nature_id: nature.id) }

  scope :unpaid, -> { where(state: %w[order invoice]).where.not(affair: Affair.closeds) }

  state_machine :state, initial: :draft do
    state :draft
    state :estimate
    state :refused
    state :order
    state :invoice
    state :aborted

    event :propose do
      transition draft: :estimate, if: :has_content?
      transition refused: :estimate
    end
    event :correct do
      transition estimate: :draft
      transition refused: :draft
      transition order: :draft # , if: lambda{|sale| !sale.partially_closed?}
    end
    event :refuse do
      transition estimate: :refused, if: :has_content?
    end
    event :confirm do
      transition estimate: :order, if: :has_content?
    end
    event :invoice do
      transition %i[draft estimate order] => :invoice, if: :has_content?
    end
    event :abort do
      transition draft: :aborted
      transition estimate: :aborted
    end
  end

  after_initialize do
    next if persisted?

    self.state = :draft
  end

  before_validation(on: :create) do
    self.currency ||= nature.currency if nature
    self.created_at = Time.zone.now
  end

  before_validation do
    if address.nil? && client
      dc = client.default_mail_address
      self.address_id = dc.id if dc
    end
    self.delivery_address_id ||= address_id
    self.invoice_address_id ||= self.delivery_address_id
    self.created_at ||= Time.zone.now
    self.nature ||= SaleNature.by_default if nature.nil?
    if self.nature
      self.expiration_delay ||= self.nature.expiration_delay
      self.expired_at ||= Delay.new(self.expiration_delay).compute(self.created_at)
      self.payment_delay ||= self.nature.payment_delay
      self.has_downpayment = self.nature.downpayment if has_downpayment.nil?
      if amount >= self.nature.downpayment_minimum
        self.downpayment_amount ||= (amount * self.nature.downpayment_percentage * 0.01)
      end
      self.currency ||= self.nature.currency
    end
    self.payment_delay = '1 week' if payment_delay.blank?
    true
  end

  validate do
    if invoiced_at
      errors.add(:invoiced_at, :before, restriction: Time.zone.now.l) if invoiced_at > Time.zone.now

      linked_fixed_asset_ids = items.map(&:fixed_asset_id).compact
      if linked_fixed_asset_ids.any?
        latest_start_date = FixedAsset.where(id: linked_fixed_asset_ids).maximum(:started_on)
        errors.add(:invoiced_at, :on_or_after, restriction: latest_start_date.l) if invoiced_at.to_date < latest_start_date
      end
    end
    %i[address delivery_address invoice_address].each do |mail_address|
      next unless send(mail_address)

      unless send(mail_address).mail?
        errors.add(mail_address, :must_be_a_mail_address)
      end
    end
  end

  before_update do
    if old_record.present? && old_record.invoice?
      self.class.columns_definition.keys.each do |attr|
        send(attr + '=', old_record.send(attr))
      end
    end
  end

  after_update do
    if self.aborted? && self.journal_entry.presence && self.journal_entry.destroyable?
      self.journal_entry.destroy
    end
  end

  after_create do
    client.add_event(:sale_creation, updater.person) if updater && updater.person
    true
  end

  after_save do
    items.linked_to_fixed_asset.each { |item| item.fixed_asset.update_columns(sold_on: invoiced_at&.to_date) }
    items.each { |item| item.depreciable_product.update!(dead_at: invoiced_at) if item.depreciable_product } if invoice?
  end

  protect on: :update do
    old_record.invoice?
  end

  protect on: :destroy do
    old_record.invoice? || old_record.order? || !subscriptions.all?(&:destroyable?)
  end

  # This callback bookkeeps the sale depending on its state
  bookkeep do |b|
    create_sale_catalog_items if %w[invoice order].include? state
    update_sale_catalog if state == "invoice"
    # take reference_number (external ref) if exist else take number (internal ref)
    r_number = (reference_number.blank? ? number : reference_number)
    # build description on entry
    if reference_number.presence
      products_info = reference_number
    elsif description.presence
      products_info = description.gsub(/\r?\n/, ' / ')
    else
      products_info = items.pluck(:label).to_sentence
    end

    b.journal_entry(self.nature.journal, reference_number: r_number, printed_on: invoiced_on, if: ((invoice? || order?) && items.any?)) do |entry|
      label = tc(:bookkeep, resource: state_label, number: number, client: client.full_name, products: products_info, sale: initial_number)
      # TODO: Uncommented this once we handle debt correctly and account 462 has been added to nomenclature
      # if items.all? { |item| item.fixed_asset_id }
      #   affair_balanced = affair.incoming_payments.sum(:amount) == amount
      #   account_type = affair_balanced ? :banks : :debt
      #   account = Account.find_or_import_from_nomenclature account_type
      #   entry.add_debit(label, account.id, amount)
      # else
      #   entry.add_debit(label, client.account(:client).id, amount, as: :client)
      # end
      entry.add_debit(label, client.account(:client).id, amount, as: :client)
      items.each do |item|
        entry.add_credit(label, (item.account || item.variant.product_account).id, item.pretax_amount, activity_budget: item.activity_budget, team: item.team, as: :item_product, resource: item, variant: item.variant, accounting_label: item.accounting_label.present? ? "#{item.accounting_label} (#{initial_number})" : nil)
        tax = item.tax
        entry.add_credit(label, tax.collect_account_id, item.taxes_amount, tax: tax, pretax_amount: item.pretax_amount, as: :item_tax, resource: item, variant: item.variant, accounting_label: item.accounting_label.present? ? "#{item.accounting_label} (#{initial_number})" : nil)
      end
    end

    # For undelivered invoice
    # exchange undelivered invoice from parcel
    journal = Journal.used_for_unbilled_payables!(currency: self.currency)
    b.journal_entry(journal, reference_number: number, printed_on: invoiced_on, as: :undelivered_invoice, if: invoice?) do |entry|
      parcels.each do |parcel|
        next unless parcel.undelivered_invoice_journal_entry

        label = tc(:exchange_undelivered_invoice, resource: parcel.class.model_name.human, number: parcel.number, entity: supplier.full_name, mode: parcel.nature.tl)
        undelivered_items = parcel.undelivered_invoice_journal_entry.items
        undelivered_items.each do |undelivered_item|
          next unless undelivered_item.real_balance.nonzero?

          entry.add_credit(label, undelivered_item.account.id, undelivered_item.real_balance, resource: undelivered_item, as: :item_product, variant: undelivered_item.variant, accounting_label: undelivered_item.accounting_label)
        end
      end
    end

    # For gap between parcel item quantity and sale item quantity
    # if more quantity on sale than parcel then i have value in C of stock account
    permanent_stock = Preference[:permanent_stock_inventory]
    journal = Journal.used_for_permanent_stock_inventory!(currency: self.currency)
    b.journal_entry(journal, reference_number: number, printed_on: invoiced_on, as: :quantity_gap_on_invoice, if: (permanent_stock && invoice? && items.any?)) do |entry|
      label = tc(:quantity_gap_on_invoice, resource: self.class.model_name.human, number: number, entity: client.full_name)

      items.each do |item|
        next unless item.variant && item.variant.storable?

        shipment_items_quantity = item.shipment_items.map(&:population).compact.sum
        gap = item.quantity - shipment_items_quantity
        next unless item.shipment_items.any? && item.shipment_items.first.unit_pretax_stock_amount

        quantity = item.shipment_items.first.unit_pretax_stock_amount
        gap_value = gap * quantity
        next if gap_value.zero?

        entry.add_credit(label, item.variant.stock_account_id, gap_value, resource: item, as: :stock, variant: item.variant, accounting_label: item.accounting_label)
        entry.add_debit(label, item.variant.stock_movement_account_id, gap_value, resource: item, as: :stock_movement, variant: item.variant, accounting_label: item.accounting_label)
      end
    end
  end

  def items_presence
    errors.add :items, :a_sale_must_have_at_least_one_sale_item if items.blank?
  end

  def invoiced_on
    dealt_at.to_date
  end

  def self.third_attribute
    :client
  end

  def self.affair_class
    SaleAffair
  end

  def default_currency
    currency || nature.currency
  end

  def third
    send(third_attribute)
  end

  # Gives the date to use for affair bookkeeping
  def dealt_at
    if invoice?
      invoiced_at
    elsif order?
      confirmed_at
    else
      created_at
    end
  end

  # Gives the amount to use for affair bookkeeping
  def deal_amount
    (aborted? || refused? ? 0 : credit? ? -amount : amount)
  end

  # Globalizes taxes into an array of hash
  def deal_taxes(mode = :debit)
    return [] if deal_mode_amount(mode).zero?

    taxes = {}
    coeff = (credit? ? -1 : 1).to_d
    # coeff *= (self.send("deal_#{mode}?") ? 1 : -1)
    items.each do |item|
      taxes[item.tax_id] ||= { amount: 0.0.to_d, tax: item.tax }
      taxes[item.tax_id][:amount] += coeff * item.amount
    end
    taxes.values
  end

  def partially_closed?
    !affair.debit.zero? && !affair.credit.zero?
  end

  def supplier
    Entity.of_company
  end

  delegate :number, to: :client, prefix: true
  delegate :vat_number, to: :client, prefix: true
  delegate :third_attribute, to: :class

  def nature=(value)
    super(value)
    self.currency = self.nature.currency if self.nature
  end

  # Save a new time
  def refresh
    save
  end

  # Test if there is some items in the sale.
  def has_content?
    items.any?
  end

  def opened_financial_year?
    FinancialYear.on(invoiced_at)&.opened?
  end

  def invoiced_during_financial_year_closure_preparation?
    FinancialYear.on(invoiced_at)&.closure_in_preparation?
  end

  # Returns if the sale has been validated and so if it can be
  # considered as sold.
  def sold?
    (order? || invoice?)
  end

  # Check if sale can generate parcel from all the items of the sale
  def can_generate_parcel?
    items.any? && delivery_address && (order? || invoice?)
  end

  # Return at draft state
  def correct
    return false unless can_correct?

    super
  end

  # Confirm the sale order. This permits to define parcels and assert validity of sale
  def confirm(confirmed_at = Time.zone.now)
    return false unless can_confirm?

    update!(confirmed_at: confirmed_at || Time.zone.now)
    super
  end

  # Invoices all the products creating the delivery if necessary.
  # Changes number with an invoice number saving exiting number in +initial_number+.
  def invoice(invoiced_at = Time.zone.now)
    return false unless can_invoice?

    ApplicationRecord.transaction do
      # Set values for invoice
      self.invoiced_at ||= invoiced_at
      self.confirmed_at ||= self.invoiced_at
      self.payment_at ||= Delay.new(self.payment_delay).compute(self.invoiced_at)
      self.initial_number = number

      if sequence = Sequence.of(:sales_invoices)
        loop do
          self.number = sequence.next_value!
          break unless self.class.find_by(number: number)
        end
      end

      save!

      client.add_event(:sales_invoice_creation, updater.person) if updater

      return super
    end
    false
  end

  def duplicatable?
    !credit
  end

  # Duplicates a +sale+ in estimate state with its items and its active
  # subscriptions
  def duplicate(attributes = {})
    raise StandardError.new('Uncancelable sale') unless duplicatable?

    hash = %i[
      client_id nature_id letter_format annotation subject
      function_title introduction conclusion description custom_fields
    ].each_with_object({}) do |field, h|
      h[field] = send(field)
    end
    # Items
    items_attributes = {}
    items.order(:position).each_with_index do |item, index|
      attrs = %i[
        variant_id quantity amount label pretax_amount annotation conditioning_quantity
        reduction_percentage tax_id unit_amount unit_pretax_amount conditioning_unit
      ].each_with_object({}) do |field, h|
        h[field] = item.send(field)
      end
      # Subscription
      subscription = item.subscription
      if subscription
        attrs[:subscription_attributes] = subscription.following_attributes
      end
      items_attributes[index.to_s] = attrs
    end
    hash[:items_attributes] = items_attributes
    self.class.create!(hash.with_indifferent_access.deep_merge(attributes))
  end

  # Prints human name of current state
  def state_label
    translation_key =
    if invoice?
      if self.affair.closed?
        "invoiced_and_paid_sale"
      elsif self.affair.credit.zero?
        "unpaid_invoice"
      else
        "incoming_payment_different_from_the_amount_of_the_invoice"
      end
    elsif aborted?
      "aborted"
    elsif order?
      if self.affair.closed?
        "paid_order"
      else
        "order"
      end
    elsif (draft? && DateTime.now > self.expired_at) || (estimate? && DateTime.now > self.expired_at)
      "expired_quote"
    elsif draft?
      "draft_quote"
    elsif estimate?
      "estimate"
    elsif refused?
      "refused_quote"
    else
      "invalid_state"
    end

    I18n.t("tooltips.models.sale.#{translation_key}")
  end

  # Returns true if there is some products to deliver
  def deliverable?
    # not self.undelivered(:quantity).zero? and (self.invoice? or self.order?)
    # !self.undelivered_items.count.zero? and (self.invoice? or self.order?)
    true
  end

  # Label of the sales order depending on the state and the number
  def name
    tc("label.#{credit? && invoice? ? :credit : state}", number: number)
  end

  alias label name

  # Alias for letter_format? method
  def letter?
    letter_format?
  end

  def mail_address
    (address || client.default_mail_address).mail_coordinate
  end

  def number_label
    tc('number_label.' + (estimate? ? 'proposal' : 'command'), number: number)
  end

  def taxes_amount
    amount - pretax_amount
  end

  def ratio_conditioning?
    items.any?{|item| (coeff = item.conditioning_unit&.coefficient).present? && coeff != 1}
  end

  def sales_mentions
    # get preference for sales conditions
    preference_sales_conditions = Preference.global.find_by(name: :sales_conditions)
    if preference_sales_conditions
      return preference_sales_conditions.value
    else
      return nil
    end
  end

  # Build general sales condition for the sale order
  def sales_conditions
    c = []
    c << tc('sales_conditions.downpayment', percentage: self.nature.downpayment_percentage, amount: self.downpayment_amount.l(currency: self.currency)) if amount > self.nature.downpayment_minimum && has_downpayment
    c << tc('sales_conditions.validity', expiration: self.expired_at.l)
    c += self.nature.sales_conditions.to_s.split(/\s*\n\s*/) if self.nature.sales_conditions
    # c += self.responsible.team.sales_conditions.to_s.split(/\s*\n\s*/) if self.responsible and self.responsible.team
    c
  end

  def unpaid_days
    (Time.zone.now - self.invoiced_at) if invoice?
  end

  def products
    items.map { |item| item.product.name }.join(', ')
  end

  # Returns true if sale is cancellable as an invoice
  def cancellable?
    !credit? && invoice? && amount + credits.sum(:amount) > 0
  end

  def cancel!
    s = build_credit
    s.save!
    s.invoice!
  end

  # Build a new sale with new items ready for correction and save
  def build_credit
    attrs = %i[affair client address responsible nature
               currency invoice_address transporter].each_with_object({}) do |attribute, hash|
      hash[attribute] = send(attribute) unless send(attribute).nil?
      hash
    end
    attrs[:invoiced_at] = Time.zone.now
    attrs[:credit] = true
    attrs[:credited_sale] = self
    sale_credit = Sale.new(attrs)
    x = []
    items.each do |item|
      attrs = %i[account currency variant reduction_percentage tax
                 compute_from unit_pretax_amount unit_amount conditioning_unit].each_with_object({}) do |attribute, hash|
        hash[attribute] = item.send(attribute) unless item.send(attribute).nil?
        hash
      end
      %i[pretax_amount amount].each do |v|
        attrs[v] = -1 * item.send(v)
      end
      attrs[:credited_quantity] = item.creditable_quantity
      attrs[:conditioning_quantity] = -1 * item.creditable_quantity
      attrs[:credited_item] = item
      if attrs[:credited_quantity] > 0
        sale_credit_item = sale_credit.items.build(attrs)
        sale_credit_item.valid?
      end
    end
    sale_credit
  end

  # Returns status of affair if invoiced else "stop"
  def status
    if (invoice? || order?) && affair
      affair.status
    else
      :stop
    end
  end

  def human_status
    state_label
  end

  private

    def create_sale_catalog_items
      items.each do |sale_item|
        next unless (catalog = nature.catalog) && Preference.global.find_by(name: :use_sale_catalog)&.value
        next unless sale_item.catalog_item_update

        invoice_date = invoiced_at || Time.now
        item = CatalogItem.find_by(catalog: catalog, variant: sale_item.variant, unit: sale_item.conditioning_unit)
        next if item || sale_item.unit_pretax_amount.blank? || sale_item.unit_pretax_amount.zero?

        sale_item.variant.catalog_items.create!(catalog: catalog,
                                      all_taxes_included: false,
                                      amount: sale_item.unit_pretax_amount,
                                      currency: sale_item.currency,
                                      sale_item: sale_item,
                                      started_at: invoice_date,
                                      reference_tax: sale_item.tax,
                                      unit: sale_item.conditioning_unit)
      end
    end

    def update_sale_catalog
      if Preference.global.find_by(name: :use_sale_catalog)&.value
        items.each do |item|
          next unless item.catalog_item_update

          catalog_item = nature.catalog.items.of_variant(item.variant).active_at(invoiced_at).of_unit(item.conditioning_unit).first
          if catalog_item && item.unit_pretax_amount != catalog_item.amount

            if catalog_item.started_at == invoiced_at
              catalog_item.update!(amount: item.unit_pretax_amount)
            else
              catalog_item.update!(stopped_at: invoiced_at)

              CatalogItem.create!(
                variant_id: item.variant_id,
                amount: item.unit_pretax_amount,
                reference_tax: item.tax,
                started_at: invoiced_at,
                unit_id: item.conditioning_unit_id,
                catalog_id: nature.catalog.id
              )
            end

          end
        end
      end
    end
end
