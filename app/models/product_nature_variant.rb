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
# == Table: product_nature_variants
#
#  active                    :boolean          default(TRUE), not null
#  category_id               :integer          not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  custom_fields             :jsonb
#  derivative_of             :string
#  france_maaid              :string
#  gtin                      :string
#  id                        :integer          not null, primary key
#  imported_from             :string
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  nature_id                 :integer          not null
#  number                    :string           not null
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  provider                  :jsonb
#  providers                 :jsonb
#  reference_name            :string
#  specie_variety            :string
#  stock_account_id          :integer
#  stock_movement_account_id :integer
#  type                      :string           not null
#  unit_name                 :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  variety                   :string           not null
#  work_number               :string
#

class ProductNatureVariant < ApplicationRecord
  include Attachable
  include Autocastable
  include Customizable
  include Importable
  include Providable
  include Categorizable

  STOCK_INDICATOR_PER_DIMENSION = {
    volume: :net_volume,
    mass: :net_mass,
    surface_area: :net_surface_area,
    distance: :net_length,
    time: :usage_duration,
    energy: :energy
  }.freeze

  attr_readonly :number
  refers_to :variety
  refers_to :derivative_of, class_name: 'Variety'
  enumerize :type, in: %w[Animal Article Crop Equipment Service Worker Zone].map { |t| "Variants::#{t}Variant" } +
                       %w[FarmProduct Fertilizer PlantMedicine SeedAndPlant].map { |t| "Variants::Articles::#{t}Article" } +
                       %w[FixedEquipment MotorizedEquipment Tool TrailedEquipment].map { |t| "Variants::Equipments::#{t}Equipment" }
  belongs_to :nature, class_name: 'ProductNature', inverse_of: :variants
  belongs_to :category, class_name: 'ProductNatureCategory', inverse_of: :variants
  belongs_to :default_unit, class_name: 'Unit'
  has_many :catalog_items, foreign_key: :variant_id, dependent: :destroy
  has_many :conditionings, through: :catalog_items, source: :unit

  has_many :root_components, -> { where(parent: nil) }, class_name: 'ProductNatureVariantComponent', dependent: :destroy, inverse_of: :product_nature_variant, foreign_key: :product_nature_variant_id
  has_many :components, class_name: 'ProductNatureVariantComponent', dependent: :destroy, inverse_of: :product_nature_variant, foreign_key: :product_nature_variant_id

  has_many :part_product_nature_variant_id, class_name: 'ProductNatureVariantComponent'

  belongs_to :stock_movement_account, class_name: 'Account'
  belongs_to :stock_account, class_name: 'Account'

  has_many :contract_items, foreign_key: :variant_id, dependent: :restrict_with_exception
  has_many :reception_items, class_name: 'ReceptionItem', foreign_key: :variant_id, dependent: :restrict_with_exception
  has_many :shipment_items, class_name: 'ShipmentItem', foreign_key: :variant_id, dependent: :restrict_with_exception
  has_many :products, foreign_key: :variant_id, dependent: :restrict_with_exception
  has_many :inventories, through: :category
  has_many :members, class_name: 'Product', foreign_key: :member_variant_id, dependent: :restrict_with_exception
  has_many :purchase_items, foreign_key: :variant_id, inverse_of: :variant, dependent: :restrict_with_exception
  has_many :sale_items, foreign_key: :variant_id, inverse_of: :variant, dependent: :restrict_with_exception
  has_many :journal_entry_items, foreign_key: :variant_id, inverse_of: :variant, dependent: :restrict_with_exception
  has_many :readings, class_name: 'ProductNatureVariantReading', foreign_key: :variant_id, inverse_of: :variant
  has_many :phases, class_name: 'ProductPhase', foreign_key: :variant_id, inverse_of: :variant
  has_many :intervention_template_product_parameters, class_name: 'InterventionTemplate::ProductParameter', foreign_key: :product_nature_variant_id, inverse_of: :product_nature_variant
  has_picture

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, inclusion: { in: [true, false] }
  validates :default_quantity, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :category, :default_unit, :default_unit_name, :nature, :variety, presence: true
  validates :france_maaid, :gtin, :pictogram, :picture_content_type, :picture_file_name, :reference_name, :specie_variety, :unit_name, :work_number, length: { maximum: 500 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :number, presence: true, uniqueness: true, length: { maximum: 500 }
  validates :picture_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :picture_updated_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :number, length: { allow_nil: true, maximum: 60 }
  validates :derivative_of, :variety, length: { allow_nil: true, maximum: 120 }
  validates :gtin, length: { allow_nil: true, maximum: 14 }
  validates :default_quantity, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000 }
  validate :readings_presence
  validates_attachment_content_type :picture, content_type: /image/

  alias_attribute :commercial_name, :name

  delegate :able_to?, :identifiable?, :able_to_each?, :has_indicator?, :matching_model, :indicators, :population_frozen?, :population_modulo, :frozen_indicators, :frozen_indicators_list, :variable_indicators, :variable_indicators_list, :linkage_points, :of_expression, :population_counting_unitary?, :population_counting_decimal?, :whole_indicators_list, :whole_indicators, :individual_indicators_list, :individual_indicators, to: :nature
  delegate :variety, :derivative_of, :name, to: :nature, prefix: true
  delegate :depreciable?, :depreciation_rate, :deliverable?, :purchasable?, :saleable?, :storable?, :subscribing?, :fixed_asset_depreciation_method, :fixed_asset_depreciation_percentage, :fixed_asset_account, :fixed_asset_allocation_account, :fixed_asset_expenses_account, :product_account, :charge_account, to: :category
  delegate :dimension, :of_dimension?, to: :default_unit

  accepts_nested_attributes_for :products, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :components, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :readings, reject_if: ->(params) { params['measure_value_value'].blank? && params['integer_value'].blank? && params['boolean_value'].blank? && params['decimal_value'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :catalog_items, reject_if: :all_blank, allow_destroy: true
  validates_associated :components

  enumerize :default_unit_name, in: Unit::BASE_UNIT_PER_DIMENSION.values

  scope :active, -> { where(active: true) }
  scope :availables, -> { where(nature_id: ProductNature.availables).order(:name) }
  scope :saleables, -> { joins(:category).merge(ProductNatureCategory.saleables) }
  scope :purchaseables, -> { joins(:category).merge(ProductNatureCategory.purchaseables) }
  scope :deliverables, -> { joins(:category).merge(ProductNatureCategory.stockables) }
  scope :stockables_or_depreciables, -> { joins(:category).merge(ProductNatureCategory.stockables_or_depreciables).order(:name) }
  scope :depreciables, -> { joins(:category).merge(ProductNatureCategory.depreciables).order(:name) }
  scope :identifiables, -> { where(nature: ProductNature.identifiables) }
  scope :services, -> { where(nature: ProductNature.services) }
  scope :tools, -> { where(nature: ProductNature.tools) }

  scope :purchaseables_stockables_or_depreciables, -> { ProductNatureVariant.purchaseables.merge(ProductNatureVariant.stockables_or_depreciables) }
  scope :purchaseables_not_services, -> { ProductNatureVariant.purchaseables.where.not(nature: ProductNature.services) }
  scope :purchaseables_services, -> { ProductNatureVariant.purchaseables.merge(ProductNatureVariant.services) }
  scope :outputs_budgets, ->(campaign) { where(id: ActivityBudgetItem.joins(:activity_budget).merge(ActivityBudget.of_campaign(campaign)).revenues.pluck(:variant_id)).reorder(:name) }

  scope :derivative_of, ->(*varieties) { of_derivative_of(*varieties) }

  scope :can, ->(*abilities) { of_expression(abilities.map { |a| "can #{a}" }.join(' or ')) }
  scope :can_each, ->(*abilities) { of_expression(abilities.map { |a| "can #{a}" }.join(' and ')) }
  scope :of_working_set, ->(working_set) {
    if item = Onoma::WorkingSet.find(working_set)
      of_expression(item.expression)
    else
      raise StandardError.new("#{working_set.inspect} is not in Onoma::WorkingSet nomenclature")
    end
  }

  scope :of_expression, ->(expression) {
    joins(:nature).where(WorkingSet.to_sql(expression, default: :product_nature_variants, abilities: :product_natures, indicators: :product_natures))
  }

  scope :of_natures, ->(natures) { where(nature: natures) }

  scope :of_categories, ->(*categories) { where(category_id: categories) }

  scope :of_category, ->(category) { where(category: category) }

  scope :of_id, ->(id) { where(id: id) }

  scope :with_name, ->(name) {
    name_match_rule = "#{Regexp.escape(name)}(\\s\\(\\d*\\))?$" # match "variant", "variant (1)" ,etc.
    where("name ~ ?", name_match_rule)
  }

  protect(on: :destroy) do
    products.any? || sale_items.any? || purchase_items.any? ||
      reception_items.any? || shipment_items.any? || phases.any? || intervention_template_product_parameters.any?
  end

  before_validation on: :create do
    if ProductNatureVariant.any?
      if category
        num = ProductNatureVariant.order('number::INTEGER DESC').first.number.to_i.to_s.rjust(6, '0').succ
        if category.storable?
          while Account.where(number: [category.stock_movement_account.number + num, category.stock_account.number + num]).any? || ProductNatureVariant.where(number: num).any?
            num.succ!
          end
        end
        self.number = num
      end
    else
      self.number = '000001'
    end

    unless from_lexicon?
      type_allocator = Variants::TypeAllocatorService.new(category: category, nature: nature)
      self.type = type_allocator.find_type
    end
  end

  before_validation on: :update do
    if changes_to_save.key?('category_id') || changes_to_save.key?('nature_id')
      type_allocator = Variants::TypeAllocatorService.new(category: category, nature: nature)
      self.type = type_allocator.find_type
    end
  end

  before_validation do
    if nature.present?
      self.nature_name ||= nature.name
      self.name ||= self.nature_name
      self.variety ||= nature.variety

      if derivative_of.blank? && nature.derivative_of
        self.derivative_of ||= nature.derivative_of
      end

      if category && storable?
        self.stock_account ||= create_unique_account(:stock)
        self.stock_movement_account ||= create_unique_account(:stock_movement)
      end
    end
    self.default_unit ||= Unit.import_from_lexicon(default_unit_name) if default_unit_name
    self.default_unit_name ||= default_unit.reference_name if default_unit
    self.unit_name ||= default_unit.name if default_unit
  end

  validate do
    if nature.present?
      nv = Onoma::Variety.find(nature_variety)
      unless nv >= self.variety
        logger.debug "#{nature_variety}#{Onoma::Variety.all(nature_variety)} not include #{self.variety.inspect}"
        errors.add(:variety, :is, thing: nv.human_name)
      end

      if Onoma::Variety.find(nature_derivative_of)
        if self.derivative_of
          unless Onoma::Variety.find(nature_derivative_of) >= self.derivative_of
            errors.add(:derivative_of, :invalid)
          end
        else
          errors.add(:derivative_of, :blank)
        end
      end
    end

    if variety.present? && products.any?
      if products.detect { |p| Onoma::Variety.find(p.variety) > variety }
        errors.add(:variety, :invalid)
      end
    end

    if derivative_of.present? && products.any?
      if products.detect { |p| p.derivative_of? && Onoma::Variety.find(p.derivative_of) > derivative_of }
        errors.add(:derivative_of, :invalid)
      end
    end
  end

  # def unit_name
  # self.attributes['unit_name'] || I18n.translate("enumerize.product_nature_variant.default_unit_name.#{default_unit_name}")
  # end

  def name_with_unit
    "#{name} (#{unit_name})"
  end

  # create unique account for stock management in accountancy
  def create_unique_account(mode = :stock)
    account_key = mode.to_s + '_account'

    category_account = category.send(account_key)
    unless category_account
      # We want to notice => raise.
      raise "Account '#{account_key}' is not configured on category of #{self.name.inspect} variant. You have to check category first"
    end

    category_account
  end

  def variant_type
    Maybe(type).constantize.variant_type.or_nil
  end

  # add animals to new variant
  def add_products(products, options = {})
    Intervention.write(:product_evolution, options) do |i|
      i.cast :variant, self, as: 'product_evolution-variant'
      products.each do |p|
        product = (p.is_a?(Product) ? p : Product.find(p))
        member = i.cast :product, product, as: 'product_evolution-target'
        i.variant_cast :variant, member
      end
    end
  end

  # Measure a product for a given indicator
  def read!(indicator, value)
    unless indicator.is_a?(Onoma::Item)
      indicator = Onoma::Indicator.find(indicator)
      unless indicator
        raise ArgumentError.new("Unknown indicator #{indicator.inspect}. Expecting one of them: #{Onoma::Indicator.all.sort.to_sentence}.")
      end
    end
    reading = readings.find_or_initialize_by(indicator_name: indicator.name)
    reading.value = value
    reading.save!
    reading
  end

  # Builds the reading instead of saving it
  def read(indicator, value)
    unless indicator.is_a?(Onoma::Item)
      indicator = Onoma::Indicator.find(indicator)
      unless indicator
        raise ArgumentError.new("Unknown indicator #{indicator.inspect}. Expecting one of them: #{Onoma::Indicator.all.sort.to_sentence}.")
      end
    end
    reading = readings.find_or_initialize_by(indicator_name: indicator.name)
    reading.value = value
    reading
  end

  # Return the reading
  def reading(indicator)
    unless indicator.is_a?(Onoma::Item) || indicator = Onoma::Indicator[indicator]
      raise ArgumentError.new("Unknown indicator #{indicator.inspect}. Expecting one of them: #{Onoma::Indicator.all.sort.to_sentence}.")
    end

    readings.find_by(indicator_name: indicator.name)
  end

  # Returns the direct value of an indicator of variant
  def get(indicator, *args)
    unless indicator.is_a?(Onoma::Item) || indicator = Onoma::Indicator[indicator]
      raise ArgumentError.new("Unknown indicator #{indicator.inspect}. Expecting one of them: #{Onoma::Indicator.all.sort.to_sentence}.")
    end
    if reading = reading(indicator.name)
      return reading.value
    elsif indicator.datatype == :measure
      return 0.0.in(indicator.unit)
    elsif indicator.datatype == :decimal
      return 0.0
    end

    nil
  end

  # check if a variant has an indicator which is frozen or not
  def has_frozen_indicator?(indicator)
    if indicator.is_a?(Onoma::Item)
      frozen_indicators.include?(indicator)
    else
      frozen_indicators_list.include?(indicator)
    end
  end

  # Returns last item from default catalog for given usage with similar dimension unit and before at.
  # mode [:unit, :dimension]
  def default_catalog_item(usage, at = Time.now, into = default_unit, mode = :base_unit)
    destination_unit = into.is_a?(Unit) ? into : Unit.import_from_lexicon(into)
    raise ArgumentError.new("Unknown unit #{into}") unless destination_unit.present?

    catalog = Catalog.by_default!(usage)
    if mode == :dimension
      catalog.items.of_variant(self).where(product_id: nil).of_dimension_unit(destination_unit.dimension).started_before(at).reorder('started_at DESC').first
    elsif mode == :base_unit
      catalog.items.of_variant(self).where(product_id: nil).of_base_unit(destination_unit.base_unit).started_before(at).reorder('started_at DESC').first
    else
      raise ArgumentError.new("Unknown mode #{mode}")
    end
  end

  # Returns a list of couple indicator/unit usable for the given variant
  # The result is only based on measure indicators
  def quantifiers
    list = []
    indicators.each do |indicator|
      next unless indicator.gathering == :proportional_to_population

      if indicator.datatype == :measure
        Measure.siblings(indicator.unit).each do |unit_name|
          list << "#{indicator.name}/#{unit_name}"
        end
      elsif indicator.datatype == :integer || indicator.datatype == :decimal
        list << indicator.name.to_s
      end
    end
    variety = Onoma::Variety.find(self.variety)
    # Specials indicators
    if variety <= :product_group
      list << 'members_count' unless list.include?('members_count/unity')
      if variety <= :animal_group
        list << 'members_livestock_unit' unless list.include?('members_livestock_unit/unity')
      end
      list << 'members_population' unless list.include?('members_population/unity')
    end
    list
  end

  # Returns a list of quantifier
  def unified_quantifiers(options = {})
    list = quantifiers.map do |quantifier|
      pair = quantifier.split('/')
      indicator = Onoma::Indicator.find(pair.first)
      unit = (pair.second.blank? ? nil : Onoma::Unit.find(pair.second))
      hash = { indicator: { name: indicator.name, human_name: indicator.human_name } }
      hash[:unit] = if unit
                      { name: unit.name, symbol: unit.symbol, human_name: unit.human_name }
                    elsif indicator.name =~ /^members\_/
                      unit = Onoma::Unit.find(:unity)
                      { name: '', symbol: unit.symbol, human_name: unit.human_name }
                    else
                      { name: '', symbol: unit_name, human_name: unit_name }
                    end
      hash
    end

    # Add population
    if options[:population]
      # indicator = Onoma::Indicator[:population]
      list << { indicator: { name: :population, human_name: Product.human_attribute_name(:population) }, unit: { name: '', symbol: unit_name, human_name: unit_name } }
    end

    # Add working duration (intervention durations)
    if options[:working_duration]
      Onoma::Unit.where(dimension: :time).find_each do |unit|
        list << { indicator: { name: :working_duration, human_name: :working_duration.tl }, unit: { name: unit.name, symbol: unit.symbol, human_name: unit.human_name } }
      end
    end

    list
  end

  def contractual_prices
    contract_items
      .pluck(:contract_id, :unit_pretax_amount)
      .to_h
      .map { |contract_id, price| [Contract.find(contract_id), price] }
      .to_h
  end

  # Get indicator value
  # if option :at specify at which moment
  # if option :reading is true, it returns the ProductNatureVariantReading record
  # if option :interpolate is true, it returns the interpolated value
  # :interpolate and :reading options are incompatible
  def method_missing(method_name, *args)
    return super unless Onoma::Indicator.items[method_name]

    get(method_name)
  end

  def generate(*args)
    options = args.extract_options!
    product_name = args.shift || options[:name]
    born_at = args.shift || options[:born_at]
    default_storage = args.shift || options[:default_storage]

    product_model = nature.matching_model

    product_model.create!(variant: self, name: product_name + ' ' + born_at.l, initial_owner: Entity.of_company, initial_born_at: born_at, default_storage: default_storage)
  end

  # Shortcut for creating a new product of the variant
  def create_product!(attributes = {})
    attributes = product_params(attributes)
    matching_model.create!(attributes.merge(variant: self))
  end

  def create_product(attributes = {})
    attributes = product_params(attributes)
    matching_model.create(attributes.merge(variant: self))
  end

  def product_params(attributes = {})
    attributes[:initial_owner] ||= Entity.of_company
    attributes[:initial_born_at] ||= Time.zone.now
    attributes[:born_at] ||= attributes[:initial_born_at]
    attributes[:name] ||= "#{name} (#{attributes[:initial_born_at].to_date.l})"
    attributes
  end

  def take(quantity)
    products.mine.each_with_object({}) do |product, result|
      reminder = quantity - result.values.sum
      result[product] = [product.population, reminder].min if reminder > 0
      result
    end
  end

  def take!(quantity)
    raise 'errors.not_enough'.t if take(quantity).values.sum < quantity
  end

  # Returns last purchase item for the variant
  # and a given supplier if any, or nil if there's
  # no purchase item matching criterias
  def last_purchase_item_for(supplier = nil)
    return purchase_items.last if supplier.blank?

    purchase_items
      .joins(:purchase)
      .where('purchases.supplier_id = ?', Entity.find(supplier).id)
      .last
  end

  def quantity_purchased
    purchase_items.sum(:quantity)
  end

  def quantity_received
    reception_items.joins(:reception).where(parcels: { state: :given }).sum(:population)
  end

  # Return current stock of all products link to the variant
  def current_stock(into_default_unit: false)
    if variety == 'service'
      quantity_purchased - quantity_received
    elsif into_default_unit
      products.alive.map { |product| UnitComputation.convert_into_variant_default_unit(product.variant, product.population, product.conditioning_unit) }.sum
    else
      products.alive.map { |product| UnitComputation.convert_into_variant_population(product.variant, product.population, product.conditioning_unit) }.sum
    end
  end

  def current_stock_displayed
    variety == 'service' ? '' : current_stock
  end

  # TODO: refacto with conditioning
  # Return current quantity of all products link to the variant currently ordered or invoiced but not delivered
  def current_outgoing_stock_ordered_not_delivered(into_default_unit: false)
    undelivereds = sale_items.includes(:sale).map do |si|
      undelivered = 0
      variants_in_parcel_in_sale = ShipmentItem.where(parcel_id: si.sale.parcels.select(:id), variant: self)
      variants_in_transit_parcel_in_sale = ShipmentItem.where(parcel_id: si.sale.parcels.where.not(state: %i[given draft]).select(:id), variant: self)
      delivered_variants_in_parcel_in_sale = ShipmentItem.where(parcel_id: si.sale.parcels.where(state: :given).select(:id), variant: self)

      undelivered = si.quantity if variants_in_parcel_in_sale.none? && !si.sale.draft? && !si.sale.refused? && !si.sale.aborted?
      undelivered = [undelivered, si.quantity - delivered_variants_in_parcel_in_sale.sum(:population)].max if variants_in_parcel_in_sale.present?
      sale_not_canceled = (si.sale.draft? || si.sale.estimate? || si.sale.order? || si.sale.invoice?)
      undelivered = [undelivered, variants_in_transit_parcel_in_sale.sum(:population)].max if sale_not_canceled && variants_in_transit_parcel_in_sale.present?

      undelivered
    end

    undelivereds += shipment_items.joins(:shipment).where.not(parcels: { state: %i[given draft] }).where(parcels: { sale_id: nil, nature: :outgoing }).pluck(:population)

    into_default_unit ? undelivereds.compact.sum * default_quantity : undelivereds.compact.sum
  end

  def current_outgoing_stock_ordered_not_delivered_displayed
    variety == 'service' ? '' : current_outgoing_stock_ordered_not_delivered(into_default_unit: true)
  end

  def picture_path(style = :original)
    picture.path(style)
  end

  def current_stock_per_storage(storage)
    ParcelItemStoring.where(storage: storage)
                     .joins(:parcel_item)
                     .where(parcel_items: { variant_id: self.id })
                     .sum(:quantity)
  end

  def default_unit_updateable?
    products.none? && catalog_items.none? && purchase_items.none? && sale_items.none? && shipment_items.none? && reception_items.none?
  end

  def guess_conditioning
    unit = Unit.find_by(base_unit: default_unit, coefficient: default_quantity)
    unit ? { unit: unit, quantity: 1 } : { unit: default_unit, quantity: default_quantity }
  end

  def phytosanitary_product
    if imported_from == "Lexicon"
      RegisteredPhytosanitaryProduct.find_by_reference_name reference_name
    else
      nil
    end
  end

  def status
    phyto = phytosanitary_product
    if phyto&.authorized?
      :go
    elsif phyto&.withdrawn?
      :stop
    else
      nil
    end
  end

  def human_status
    return unless status

    I18n.t("tooltips.models.product_nature_variant.#{status}")
  end

  def compatible_dimensions
    readings.stock_related.map { |r| Unit.import_from_lexicon(r.measure_value_unit).dimension }.push(dimension, 'none').uniq
  end

  # LUCAS TODO: Add tests for this
  def readings_presence
    return if !default_unit || of_dimension?(:none)

    mandatory_reading_name = Unit::STOCK_INDICATOR_PER_DIMENSION[dimension.to_sym]
    mandatory_reading = readings.detect { |r| r.indicator_name == mandatory_reading_name }
    if !mandatory_reading || !mandatory_reading.valid?
      errors.add(:base, :mandatory_reading, name: Onoma::Indicator.find(mandatory_reading_name).human_name)
    end
  end

  # Return revelent stock indicator of the dimension
  #
  # @param dimension [String] dimension
  # @return [Measure]
  def relevant_stock_indicator(dimension)
    indicator_name = Unit::STOCK_INDICATOR_PER_DIMENSION[dimension.to_sym]
    indicator_name ? send(indicator_name) : Measure.new(1, :unity)
  end

  def last_inventory
    inventories.order(:achieved_at).last
  end

  class << self
    # Returns some nomenclature items are available to be imported, e.g. not
    # already imported
    def any_reference_available?
      Onoma::ProductNatureVariant.without(ProductNatureVariant.pluck(:reference_name).uniq).any?
    end

    # Find or import variant from nomenclature with given attributes
    # variety and derivative_of only are accepted for now
    def find_or_import!(variety, options = {})
      variants = of_variety(variety)
      if derivative_of = options[:derivative_of]
        variants = variants.derivative_of(derivative_of)
      end
      if variants.empty?
        # Filter and imports
        filtereds = flattened_nomenclature.select do |item|
          next if item.variety.nil?

          item.variety >= variety &&
            ((derivative_of && item.derivative_of && item.derivative_of >= derivative_of) || (derivative_of.blank? && item.derivative_of.blank?))
        end
        filtereds.each do |item|
          import_from_nomenclature(item.name)
        end
      end
      variants.reload
    end

    ItemStruct = Struct.new(:name, :variety, :derivative_of, :abilities_list, :indicators, :frozen_indicators, :variable_indicators)

    # Returns core attributes of nomenclature merge with nature if necessary
    # name, variety, derivative_od, abilities
    def flattened_nomenclature
      @flattened_nomenclature ||= Onoma::ProductNatureVariant.list.collect do |item|
        nature = Onoma::ProductNature[item.nature]
        f = (nature.frozen_indicators || []).map(&:to_sym)
        v = (nature.variable_indicators || []).map(&:to_sym)
        ItemStruct.new(
          item.name,
          Onoma::Variety.find(item.variety || nature.variety),
          Onoma::Variety.find(item.derivative_of || nature.derivative_of),
          WorkingSet::AbilityArray.load(nature.abilities),
          f + v, f, v
        )
      end
    end

    # Lists ProductNatureVariant::Item which match given expression
    # Fully compatible with WSQL
    def items_of_expression(expression)
      flattened_nomenclature.select do |item|
        WorkingSet.check_record(expression, item)
      end
    end

    # Load a product nature variant from product nature variant nomenclature
    def import_from_nomenclature(reference_name, force = false)
      unless item = Onoma::ProductNatureVariant[reference_name]
        raise ArgumentError.new("The product_nature_variant #{reference_name.inspect} is not known")
      end
      unless nature_item = Onoma::ProductNature[item.nature]
        raise ArgumentError.new("The nature of the product_nature_variant #{item.nature.inspect} is not known")
      end
      unless Onoma::ProductNatureCategory[nature_item.category]
        raise ArgumentError.new("The category of the product_nature_variant #{nature_item.category.inspect} is not known")
      end

      unless !force && (variant = ProductNatureVariant.find_by(reference_name: reference_name.to_s))
        computation = compute_default_unit_from_nomenclature(item)
        default_unit_name = computation[:unit]
        default_quantity = computation[:quantity]
        category = ProductNatureCategory.import_from_nomenclature(nature_item.category)
        nature = ProductNature.import_from_nomenclature(item.nature)
        default_unit = Unit.import_from_lexicon(default_unit_name)

        variant = new(
          name: item.human_name,
          active: true,
          nature: nature,
          category: category,
          reference_name: item.name,
          unit_name: I18n.translate("nomenclatures.product_nature_variants.choices.unit_name.#{item.unit_name}"),
          default_unit_name: default_unit_name,
          default_unit: default_unit,
          default_quantity: default_quantity,
          variety: item.variety || nil,
          derivative_of: item.derivative_of || nil,
          imported_from: 'Nomenclature'
        )
        build_indicators_from_nomenclature(item, variant) if item.frozen_indicators_values.to_s.present?
        unless variant.save
          raise "Cannot import variant #{reference_name.inspect}: #{variant.errors.full_messages.join(', ')}"
        end
      end
      variant
    end

    def import_from_lexicon(reference_name, force = false, new_name = '')
      if RegisteredPhytosanitaryProduct.find_by_reference_name(reference_name) || RegisteredPhytosanitaryProduct.find_by_id(reference_name)
        return import_phyto_from_lexicon(reference_name)
      end

      unless item = MasterVariant.find_by_reference_name(reference_name)
        raise ArgumentError.new("The product_nature_variant #{reference_name.inspect} is not known")
      end

      unless nature_item = MasterVariantNature.find_by_reference_name(item.nature)
        raise ArgumentError.new("The nature of the product_nature_variant #{item.nature.inspect} is not known")
      end

      unless category_item = MasterVariantCategory.find_by_reference_name(item.category)
        raise ArgumentError.new("The category of the product_nature_variant #{item.category.inspect} is not known")
      end

      variants = ProductNatureVariant.where(reference_name: reference_name)

      return variants.first if !force && variants.count > 0

      if new_name.present?
        count_same_name = ProductNatureVariant.where(name: new_name).count
        if count_same_name > 0
          variant_name = new_name + "(#{count_same_name.to_s})"
        else
          variant_name = new_name
        end
      elsif force && variants.count > 0
        variant_name = item.translation.send(Preference[:language]) + "(#{variants.count.to_s})"
      else
        variant_name = item.translation.send(Preference[:language])
      end

      category = ProductNatureCategory.import_from_lexicon(item.category)
      nature = ProductNature.import_from_lexicon(item.nature)
      default_unit_name = item.default_unit
      default_unit = Unit.import_from_lexicon(default_unit_name)
      base_unit = default_unit.base_unit
      base_unit_quantity = default_unit.coefficient

      variant = new(
        name: variant_name,
        active: true,
        nature: nature,
        category: category,
        reference_name: item.reference_name,
        pictogram: item.pictogram_name,
        variety: item.specie,
        derivative_of: item.target_specie,
        default_unit: base_unit,
        default_quantity: base_unit_quantity,
        default_unit_name: base_unit.reference_name,
        type: find_type(item),
        unit_name: default_unit.name,
        imported_from: 'Lexicon'
      )
      build_indicators_from_lexicon(item, variant)

      unless variant.save
        raise "Cannot import variant #{reference_name.inspect}: #{variant.errors.full_messages.join(', ')}"
      end

      # import price from lexicon
      MasterPrice.where(reference_article_name: reference_name).each do |v_price|
        CatalogItem.import_from_lexicon(v_price.reference_name)
      end

      variant
    end

    def load_defaults(**_options)
      MasterVariant.of_families(:service, :worker, :zone).find_each do |variant|
        import_from_lexicon(variant.reference_name)
      end
    end

    def import_all_from_nomenclature(options = {})
      pcg82_variants = %i[accommodation_taxe accommodation_travel associate_social_contribution bank_service battery building building_division building_insurance cap_subsidies car car_moving_travel computer_display computer_item daily_project_management daily_software_engineering daily_training_course discount_and_reduction electricity fiscal_fine forwarding_agent_fees_expense freelance_sofware_development gas gasoline hourly_project_management hourly_software_engineering hourly_training_course hourly_user_support infirmity_and_death_insurance ink_cartridge insurance internet_line_subscription ip_address_subscription legal_registration loan_interest maintenance manager meal_travel monthly_enterprise_support natural_water office_building office_building_division phone_line_subscription portable_computer portable_hard_disk postal_charges postal_stamp printer product_warranty project_study rent representation_suit responsibility_insurance salary_social_contribution screed_building settlement subscription_professional_society taxe truck various_loan_interest]
      variants_to_load = Onoma::ProductNatureVariant.all
      variants_to_load = pcg82_variants if options.fetch(:preferences, {}).fetch(:accounting_system, '') == 'fr_pcg82'
      variants_to_load.flatten.collect do |p|
        import_from_nomenclature(p.to_s)
      end
    end

    def import_phyto_from_lexicon(reference_name)
      item = RegisteredPhytosanitaryProduct.find_by_reference_name(reference_name) || RegisteredPhytosanitaryProduct.find_by_id(reference_name)
      unless variant = ProductNatureVariant.find_by_reference_name(item.reference_name)
        category = ProductNatureCategory.import_from_lexicon(:plant_medicine)
        nature = ProductNature.import_from_lexicon(:plant_medicine)
        default_unit_name = item.usages.any? ? get_phyto_unit(item) : :liter
        default_unit = Unit.import_from_lexicon(default_unit_name)
        base_unit = default_unit.base_unit
        base_unit_quantity = default_unit.coefficient

        variant = new(
          name: item.name.capitalize,
          reference_name: item.reference_name,
          pictogram: 'flask',
          active: true,
          nature: nature,
          france_maaid: item.france_maaid,
          category: category,
          default_unit: base_unit,
          default_quantity: base_unit_quantity,
          default_unit_name: base_unit.reference_name,
          type: "Variants::Articles::PlantMedicineArticle",
          unit_name: default_unit.name,
          imported_from: 'Lexicon'
        )
        build_phyto_indicators(item, variant)
        unless variant.save
          raise "Cannot import variant #{item.name.inspect}: #{variant.errors.full_messages.join(', ')}"
        end
      end
      variant
    end

    def load_phyto_defaults(**_options)
      RegisteredPhytosanitaryProduct.find_each do |phyto|
        import_phyto_from_lexicon(phyto.reference_name)
      end
    end

    protected

      def compute_default_unit_from_nomenclature(variant)
        unit = variant.unit_name.to_s
        indicators_string = variant.frozen_indicators_values.to_s
        indicators = indicators_string.strip.split(/[[:space:]]*\,[[:space:]]*/)

        if unit.match(/gram|ton|[0-9]\s*(kg|g|mg|t)/) && indicators_string.match(/net_mass/)
          relevant_indicator_values(indicators, 'net_mass')
        elsif unit.match(/liter|cubic|[0-9]\s*(l|cl|ml|m³)/) && indicators_string.match(/net_volume/)
          relevant_indicator_values(indicators, 'net_volume')
        elsif unit.match(/acre|are|square|[0-9]\s*(a|acre|ha|cm²|m²)/) && indicators_string.match(/net_surface_area/)
          relevant_indicator_values(indicators, 'net_surface_area')
        elsif unit.match(/meter|[0-9]\s*(mm|cm|m|km)/) && indicators_string.match(/net_length/)
          relevant_indicator_values(indicators, 'net_length')
        elsif unit.match(/day|hour|minute|second|[0-9]\s*(d|h|min|s|ms)/) && indicators_string.match(/usage_duration/)
          relevant_indicator_values(indicators, 'usage_duration')
        elsif unit.match(/joule|watt|[0-9]\s*(J|kWh)/) && indicators_string.match(/energy/)
          relevant_indicator_values(indicators, 'energy')
        else
          { unit: 'unity', quantity: 1 }
        end
      end

      def relevant_indicator_values(indicators, key)
        indicator = indicators.detect { |i| i.match(/#{Regexp.quote(key)}/) }
        quantity = indicator.match(/#{Regexp.quote(key)}:\s*(\d+\.?\d*)([a-z]+_?[a-z]*)/)[1].to_f
        unit = indicator.match(/#{Regexp.quote(key)}:\s*(\d+\.?\d*)([a-z]+_?[a-z]*)/)[2]
        indicator_unit = Unit.import_from_lexicon(unit)
        { unit: indicator_unit.base_unit.reference_name, quantity: quantity * indicator_unit.coefficient }
      end

      def get_phyto_unit(item)
        dose_unit = item.usages.group(:dose_unit).order('count_id DESC').limit(1).count(:id).keys.first
        return :liter unless dose_unit

        if formatted_unit = dose_unit.match(/\A(\w+)_per_\w+/)
          formatted_unit[1]
        else
          dose_unit
        end
      end

      def build_indicators_from_lexicon(item, variant)
        if variant.population_counting_decimal?
          Unit::STOCK_INDICATOR_PER_DIMENSION.each do |dimension, indicator|
            if variant.of_dimension?(dimension) && variant.frozen_indicators_list.include?(indicator.to_sym)
              variant.read(indicator, Measure.new(variant.default_quantity, variant.default_unit_name))
            end
          end
        end

        return unless item.indicators

        item.indicators.each do |indicator, value|
          next unless variant.has_indicator? indicator.to_sym

          variant.read(indicator.to_sym, value)
        end
      end

      def build_indicators_from_nomenclature(item, variant)
        item.frozen_indicators_values.to_s.strip.split(/[[:space:]]*\,[[:space:]]*/)
            .collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each do |i|
          indicator_name = i.first.strip.downcase.to_sym
          next unless variant.has_indicator? indicator_name

          variant.read(indicator_name, i.second)
        end
      end

      def build_phyto_indicators(item, variant)
        units = item.usages.pluck(:dose_unit).uniq.compact.map { |u| u.match(/_per_/) ? u.split('_per_').first : u }.uniq
        dimensions = units.map { |u| Onoma::Unit.find(u).dimension }.uniq
        variant.read(:net_mass, Measure.new(1, :kilogram)) if dimensions.include?(:mass)
        variant.read(:net_volume, Measure.new(1, :liter)) if dimensions.include?(:volume) || variant.of_dimension?(:volume)
      end

      def set_indicators(item, variant)
        dimension = Onoma::Unit.find(item.default_unit).dimension

        if indicator = STOCK_INDICATOR_PER_DIMENSION[dimension]
          variant.read!(indicator, Measure.new(1, item.default_unit))
        end

        item.indicators.each { |indicator, value| variant.read!(indicator, value) if variant.frozen_indicators.include?(indicator) }
      end

      def find_type(item)
        if item.sub_family.present?
          "Variants::#{item.family.classify.pluralize}::#{item.sub_family.classify + item.family.classify}"
        else
          "Variants::#{item.family.classify}Variant"
        end
      end
  end
end
