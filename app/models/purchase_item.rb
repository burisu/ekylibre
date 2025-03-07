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
# == Table: purchase_items
#
#  account_id             :integer          not null
#  accounting_label       :string
#  activity_budget_id     :integer
#  amount                 :decimal(19, 4)   default(0.0), not null
#  annotation             :text
#  conditionning          :decimal(19, 4)
#  conditionning_quantity :decimal(19, 4)
#  created_at             :datetime         not null
#  creator_id             :integer
#  currency               :string           not null
#  depreciable_product_id :integer
#  equipment_id           :integer
#  fixed                  :boolean          default(FALSE), not null
#  fixed_asset_id         :integer
#  fixed_asset_stopped_on :date
#  id                     :integer          not null, primary key
#  label                  :text
#  lock_version           :integer          default(0), not null
#  position               :integer
#  preexisting_asset      :boolean
#  pretax_amount          :decimal(19, 4)   default(0.0), not null
#  project_budget_id      :integer
#  purchase_id            :integer          not null
#  quantity               :decimal(19, 4)   not null
#  reduction_percentage   :decimal(19, 4)   default(0.0), not null
#  role                   :string
#  tax_id                 :integer          not null
#  team_id                :integer
#  unit_amount            :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount     :decimal(19, 4)   not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer
#

class PurchaseItem < ApplicationRecord
  include PeriodicCalculable
  refers_to :currency
  belongs_to :account
  belongs_to :activity_budget
  belongs_to :project_budget
  belongs_to :team
  belongs_to :purchase, inverse_of: :items
  belongs_to :equipment, class_name: 'Product', inverse_of: :purchase_items
  belongs_to :variant, class_name: 'ProductNatureVariant', inverse_of: :purchase_items
  belongs_to :tax
  belongs_to :fixed_asset, inverse_of: :purchase_items
  belongs_to :depreciable_product, class_name: 'Product'
  belongs_to :conditioning_unit, class_name: 'Unit'
  belongs_to :catalog_item

  has_many :parcels_purchase_orders_items, inverse_of: :purchase_order_item, foreign_key: 'purchase_order_item_id', dependent: :nullify, class_name: 'ReceptionItem'
  has_many :parcels_purchase_invoice_items, inverse_of: :purchase_invoice_item, foreign_key: 'purchase_invoice_item_id', dependent: :nullify, class_name: 'ReceptionItem'

  # has_many :products, through: :parcels_purchase_orders_items
  has_many :products, through: :parcels_purchase_invoice_items, source: :product
  has_one :product_nature_category, through: :variant, source: :category

  enumerize :role, in: %i[merchandise service fees], predicates: true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounting_label, length: { maximum: 500 }, allow_blank: true
  validates :amount, :pretax_amount, :quantity, :reduction_percentage, :unit_amount, :unit_pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :annotation, :label, length: { maximum: 500_000 }, allow_blank: true
  validates :conditioning_quantity, presence: true, numericality: { greater_than: -10_000_000_000, less_than: 10_000_000_000 }
  validates :account, :conditioning_unit, :currency, :purchase, :tax, presence: true
  validates :fixed, inclusion: { in: [true, false] }
  validates :fixed_asset_stopped_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years }, type: :date }, allow_blank: true
  validates :preexisting_asset, inclusion: { in: [true, false] }, allow_blank: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :currency, match: { with: :purchase }
  validates :account, :tax, :reduction_percentage, presence: true
  validates :variant, presence: true, unless: proc { |item| item.variant&.variety.eql?('trailed_equipment') || item.variant&.variety.eql?('equipment') }
  validates :quantity, exclusion: { in: [0], message: :invalid }
  validates :conditioning_unit, conditioning: true

  validates_associated :fixed_asset

  delegate :invoiced_at, :journal_entry, :number, :computation_method, :computation_method_quantity_tax?, :computation_method_tax_quantity?, :computation_method_adaptative?, :computation_method_manual?, to: :purchase
  delegate :purchased?, :draft?, :order?, :supplier, to: :purchase
  delegate :currency, to: :purchase, prefix: true
  delegate :name, to: :variant, prefix: true
  delegate :name, :amount, :short_label, to: :tax, prefix: true
  delegate :dimension, :of_dimension?, to: :unit
  # delegate :subscribing?, :deliverable?, to: :product_nature, prefix: true

  # accepts_nested_attributes_for :fixed_asset

  alias_attribute :name, :label
  alias_attribute :unit, :conditioning_unit

  acts_as_list scope: :purchase
  sums :purchase, :items, :pretax_amount, :amount

  calculable period: :month, column: :pretax_amount, at: 'purchases.invoiced_at', name: :sum, joins: :purchase

  # return all purchase items  between two dates
  scope :between, lambda { |started_at, stopped_at|
    joins(:purchase).merge(Purchase.invoiced_between(started_at, stopped_at))
  }
  # return all sale items for the consider product_nature
  scope :of_product_nature, lambda { |product_nature|
    joins(:variant).merge(ProductNatureVariant.of_natures(product_nature))
  }

  # return all sale items for the consider product_nature
  scope :of_product_nature_category, lambda { |product_nature_category|
    joins(:variant).merge(ProductNatureVariant.of_categories(product_nature_category))
  }

  scope :of_role, ->(role) { where(role: role) }

  protect on: :update do
    !self.purchase.updateable?
  end

  protect on: :destroy do
    !self.purchase.destroyable?
  end

  before_validation do
    self.currency = purchase_currency if purchase
    self.reduction_percentage ||= 0

    if fixed
      if preexisting_asset
        self.depreciable_product = nil
      else
        self.fixed_asset = nil
      end
    else
      self.fixed_asset = nil
      self.depreciable_product = nil
    end

    if tax && unit_pretax_amount
      precision = Maybe(Onoma::Currency.find(currency)).precision.or_else(2)
      self.unit_amount = tax.amount_of(unit_pretax_amount)
      raw_pretax_amount = nil
      if pretax_amount.nil? || pretax_amount.zero?
        raw_pretax_amount = unit_pretax_amount * conditioning_quantity * reduction_coefficient
        self.pretax_amount = raw_pretax_amount.round(precision)
      end
      if amount.nil? || amount.zero?
        self.amount = tax.amount_of(raw_pretax_amount || pretax_amount).round(precision)
      end
    end
    if variant
      self.quantity ||= UnitComputation.convert_into_variant_population(variant, conditioning_quantity, conditioning_unit)
      self.label = variant.commercial_name
      self.account = if fixed && purchase.purchased?
                       # select outstanding_assets during purchase
                       Account.find_or_import_from_nomenclature(:outstanding_assets)
                     else
                       variant.charge_account || Account.find_by(usages: :expenses) || Account.find_by(usages: :other_expenses)
                     end
    end
  end

  after_update do
    if fixed && fixed_asset && purchase.purchased?
      fixed_asset.reload
      amount_difference = pretax_amount.to_f - pretax_amount_before_last_save.to_f
      fixed_asset.add_amount(amount_difference) if amount_difference.nonzero?
    end
    true
  end

  after_destroy do
    if fixed && fixed_asset && purchase.purchased?
      fixed_asset.add_amount(-pretax_amount.to_f) if fixed_asset
    end
    true
  end

  validate do
    next unless fixed

    # Errors linked to fixed assets

    errors.add(:fixed, :asset_account) unless variant.fixed_asset_account
    errors.add(:fixed, :asset_expenses_account) unless variant.fixed_asset_expenses_account

    depreciation_method = variant.fixed_asset_depreciation_method
    errors.add(:fixed, :asset_depreciation_method) if depreciation_method.blank?
  end

  after_save if: proc { |item| item.purchase.is_a?(PurchaseInvoice) } do
    %i[stock purchase].each do |usage|
      catalog = Catalog.by_default!(usage)
      item = CatalogItem.find_by(catalog: catalog, variant: variant, unit: conditioning_unit, started_at: purchase.invoiced_at)
      next if catalog.nil?  || item || unit_pretax_amount.blank? || unit_pretax_amount.zero?

      catalog_item = variant.catalog_items.create!(
        catalog: catalog,
        amount: unit_pretax_amount,
        currency: currency,
        purchase_item: self,
        started_at: purchase.invoiced_at,
        unit: conditioning_unit
      )
      self.update_columns(catalog_item_id: catalog_item.id) if usage == :purchase
    end
    purchase.save!
  end

  def new_fixed_asset
    # Create asset
    asset_attributes = {
      currency: currency,
      started_on: purchase.invoiced_at.to_date,
      stopped_on: fixed_asset_stopped_on,
      depreciable_amount: pretax_amount.to_f,
      depreciation_period: Preference.get(:default_depreciation_period).value,
      depreciation_method: variant.fixed_asset_depreciation_method || :linear,
      depreciation_percentage: variant.fixed_asset_depreciation_percentage || 20,
      journal: Journal.find_by(nature: :purchases),
      asset_account: variant.fixed_asset_account, # 2
      allocation_account: variant.fixed_asset_allocation_account, # 28
      expenses_account: variant.fixed_asset_expenses_account, # 68
      product: depreciable_product
    }

    if products.any?
      asset_name = if !parcels_purchase_orders_items.empty?
                     parcels_purchase_orders_items.collect(&:name).to_sentence
                   else
                     parcels_purchase_invoice_items.collect(&:name).to_sentence
                   end
    end

    asset_name ||= name
    name_duplicate_count = FixedAsset.where('name ~ ?', "^#{Regexp.escape(name)} ?\\w*$").count
    unless name_duplicate_count.zero?
      unique_identifier = (name_duplicate_count + 1).to_s(36).upcase
      asset_name = "#{asset_name} #{unique_identifier}"
    end
    asset_attributes[:name] = asset_name

    build_fixed_asset(asset_attributes)
  end

  def create_fixed_asset
    return unless fixed

    a = new_fixed_asset

    a.save!

    self.fixed_asset = a
    self.preexisting_asset = true

    save!
  end

  def update_fixed_asset
    return unless fixed

    if preexisting_asset
      return errors.add(:fixed_asset, :fixed_asset_missing) unless fixed_asset
      return errors.add(:fixed_asset, :fixed_asset_cannot_be_modified) unless fixed_asset.draft?

      fixed_asset.reload
      fixed_asset.update_amounts
    else
      a = new_fixed_asset
      a.save!
      self.fixed_asset = a
      self.preexisting_asset = true
      save!
    end
  end

  def reduction_coefficient
    (100.0 - reduction_percentage) / 100.0
  end

  def product_name
    variant.name
  end

  def taxes_amount
    amount - pretax_amount
  end

  def designation
    d = product_name
    d << "\n" + annotation.to_s if annotation.present?
    d << "\n" + tc(:tracking, serial: tracking.serial.to_s) if tracking
    d
  end

  def undelivered_quantity
    if !parcels_purchase_orders_items.empty?
      self.quantity - parcels_purchase_orders_items.sum(&:quantity)
    else
      self.quantity - parcels_purchase_invoice_items.sum(&:quantity)
    end
  end

  # know how many percentage of invoiced VAT to declare
  def payment_ratio
    return nil unless purchase.respond_to?(:affair)

    if purchase.affair.balanced?
      1.00
    elsif purchase.affair.debit != 0.0
      (1 - (purchase.affair.balance / purchase.affair.debit)).to_f
    end
  end

  def first_reception_number
    return nil if first_reception.nil?

    return first_reception.number.concat(" (#{receptions_count})") if receptions_count > 1

    first_reception.number if receptions_count == 1
  end

  def first_reception_id
    return nil if first_reception.nil?

    first_reception.id
  end

  def human_received_quantity
    return unless purchase.is_a?(PurchaseOrder) ||  parcels_purchase_orders_items.empty?

    received_quantity.l(precision: 3)
  end

  def quantity_to_receive(into_default_unit: false)
    return unless purchase.is_a?(PurchaseOrder) ||  parcels_purchase_orders_items.empty?

    quantity = conditioning_quantity - received_quantity
    into_default_unit ? UnitComputation.convert_into_variant_default_unit(variant, quantity, conditioning_unit) : quantity
  end

  def human_quantity_to_receive
    quantity_to_receive.l(precision: 3)
  end

  def base_unit_amount
    coeff = conditioning_unit&.coefficient
    (unit_pretax_amount / coeff).round(2) if unit_pretax_amount && coeff && coeff != 1
  end

  private

    def first_reception
      if purchase.is_a?(PurchaseInvoice)
        parcels_purchase_invoice_items.first&.parcel
      elsif purchase.is_a?(PurchaseOrder)
        parcels_purchase_orders_items.first&.parcel
      else
        nil
      end
    end

    def receptions_count
      if purchase.is_a?(PurchaseInvoice)
        parcels_purchase_invoice_items.count
      elsif purchase.is_a?(PurchaseOrder)
        parcels_purchase_orders_items.count
      else
        0
      end
    end

    def received_quantity
      if merchandise?
        parcels_purchase_orders_items
          .select { |reception_item| reception_item.reception.state.to_sym == :given }
          .map { |reception_item| reception_item.storings.where(conditioning_unit: conditioning_unit).pluck(:conditioning_quantity).sum }
          .sum
      else
        parcels_purchase_orders_items.where(conditioning_unit: conditioning_unit).sum(:conditioning_quantity)
      end
    end
end
