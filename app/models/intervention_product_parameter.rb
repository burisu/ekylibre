# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2022 Ekylibre SAS
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
# == Table: intervention_parameters
#
#  allowed_entry_factor     :interval
#  allowed_harvest_factor   :interval
#  applications_frequency   :interval
#  assembly_id              :integer
#  batch_number             :string
#  component_id             :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  currency                 :string
#  dead                     :boolean          default(FALSE), not null
#  event_participation_id   :integer
#  group_id                 :integer
#  id                       :integer          not null, primary key
#  identification_number    :string
#  imputation_ratio         :decimal(19, 4)   default(1), not null
#  intervention_id          :integer          not null
#  lock_version             :integer          default(0), not null
#  new_container_id         :integer
#  new_group_id             :integer
#  new_name                 :string
#  new_variant_id           :integer
#  outcoming_product_id     :integer
#  position                 :integer          not null
#  product_id               :integer
#  quantity_handler         :string
#  quantity_indicator_name  :string
#  quantity_population      :decimal(19, 4)
#  quantity_unit_name       :string
#  quantity_value           :decimal(19, 4)
#  reference_data           :jsonb            default("{}")
#  reference_name           :string           not null
#  specie_variety           :jsonb            default("{}")
#  spray_volume_value       :decimal(19, 4)
#  type                     :string
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  usage_id                 :string
#  using_live_data          :boolean          default(TRUE)
#  variant_id               :integer
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#

class InterventionProductParameter < InterventionParameter
  DEFAULT_WORKING_ZONE_AREA_UNIT = :hectare
  belongs_to :assembly, class_name: 'Product'
  belongs_to :component, class_name: 'ProductNatureVariantComponent'
  belongs_to :intervention, inverse_of: :product_parameters
  belongs_to :product, inverse_of: :intervention_product_parameters
  belongs_to :new_container, class_name: 'Product'
  belongs_to :new_group, class_name: 'ProductGroup'
  belongs_to :new_variant, class_name: 'ProductNatureVariant'
  belongs_to :variant, class_name: 'ProductNatureVariant'
  has_many :crumbs, dependent: :destroy, foreign_key: :intervention_parameter_id
  has_many :readings, class_name: 'InterventionParameterReading', dependent: :destroy, inverse_of: :intervention_parameter, foreign_key: :parameter_id
  has_one :product_nature, through: :variant, source: :nature
  has_one :activity, through: :intervention
  has_one :campaign, through: :intervention
  has_one :event,    through: :intervention

  has_geometry :working_zone, type: :multi_polygon
  composed_of :quantity, class_name: 'Measure', mapping: [%w[quantity_value to_d], %w[quantity_unit_name unit]]
  composed_of :working_zone_area, class_name: 'Measure', mapping: [%w[working_zone_area_value to_d]], constructor: ->(value) { Measure.new(value, DEFAULT_WORKING_ZONE_AREA_UNIT) }

  validates :quantity_indicator_name, :quantity_unit_name, presence: { if: :measurable? }

  delegate :name, to: :product, prefix: true
  delegate :name, to: :variant, prefix: true
  delegate :work_name, :shape,  to: :product, prefix: true
  delegate :name, to: :product_nature, prefix: true
  delegate :evaluated_price, to: :product
  delegate :tracking, to: :product
  delegate :started_at, :stopped_at, :duration, :procedure, :currency, to: :intervention, allow_nil: true
  delegate :currency, to: :intervention, prefix: true
  delegate :matching_model, to: :variant

  accepts_nested_attributes_for :readings, allow_destroy: true

  scope :of_actor, ->(actor) { where(product_id: actor.id) }
  scope :of_actors, ->(actors) { where(product: actors) }
  scope :with_actor, -> { where.not(product_id: nil) }
  scope :with_working_zone, -> { where.not(working_zone: nil) }
  scope :with_working_zone_area, -> { where.not(working_zone_area_value: nil) }

  before_validation do
    self.intervention = group.intervention if group && !intervention
    self.currency = intervention_currency if intervention
    if reference
      if reference.handled? && quantity_handler?
        handler = reference.handler(quantity_handler)
        if handler
          self.quantity_indicator_name = handler.name
          self.quantity_unit_name = handler.unit.name if handler.unit
        end
      end
    end
    self.variant ||= product.variant if product.is_a?(Product)
    v = variant || new_variant
    if v
      catalog_item = v.catalog_items.of_usage(:stock).first
      if catalog_item && catalog_item.pretax_amount != 0.0
        self.unit_pretax_stock_amount = catalog_item.pretax_amount
      end
    end
    true
  end

  before_validation :handle_working_zone_attributes

  validate do
    next unless intervention && intervention.procedure

    if reference
      if reference.handled? && quantity_handler? && !reference.handler(quantity_handler)
        errors.add(:quantity_handler, :invalid)
      end
    elsif reference_name.present?
      errors.add(:reference_name, :invalid)
    end
    true
  end

  after_save do
    if product && dead && (!product.dead_at || product.dead_at > stopped_at)
      product.update_columns(dead_at: stopped_at)
    elsif product && !dead && product.dead_at
      product.update_columns(dead_at: nil)
    end
  end

  after_destroy do
    product.update_columns(dead_at: product.dead_first_at) if product && dead
  end

  def update_imputation_ratio(total_targets_quantity)
    total_target_quantity = working_zone_area_value || 1

    ratio = (total_target_quantity.to_f / total_targets_quantity.to_f )
    update_column(:imputation_ratio, ratio)
  end

  def name
    reference ? reference.human_name : reference_name.humanize
  end

  def human_quantity
    quantity.l if quantity
  end

  def working_area
    if working_zone_area.nonzero?
      working_zone_area.in_square_meter
    else
      nil
    end
  end

  def working_zone_svg
    working_zone.to_svg if working_zone
  end

  def quantity_handler_reference
    reference.handler(quantity_handler)
  end

  def measurable?
    quantity_handler? && quantity_handler_reference && quantity_handler_reference.measure?
  end

  def is_population?
    quantity_indicator_name == 'population'
  end

  %i[doer input output target tool].each do |role|
    role_class_name = ('Intervention' + role.to_s.camelize).freeze
    define_method role.to_s + '?' do
      type.to_s == role_class_name
    end
  end

  # Change name with default name like described in procedure
  # if default-name attribute is given too.
  # It uses interpolation to compose the wanted name. Not very i18nized
  # for now, but permits to do the job.
  def set_default_name!
    if reference.default_name? && produced = product
      produced.update_column(:name, default_name)
    end
  end

  # Compute a default with given environment
  def default_name
    text = nil
    if reference.default_name?
      words = {
        campaign: campaign.name,
        activity: activity.name
      }.with_indifferent_access
      if produced = product
        words[:variant]     = produced.variant_name
        words[:variety]     = Onoma::Variety[produced.variety].human_name
        words[:derivative_of] = (produced.derivative_of ? Onoma::Variety[produced.variety].human_name : nil)
        words[:container] = (produced.container ? produced.container.name : nil)
        words[:default_storage] = (produced.default_storage ? produced.default_storage.name : nil)
        words[:born_at]     = produced.born_at.l
        words[:born_on]     = produced.born_at.to_date.l
        words[:birth_year]  = produced.born_at.year.to_s.rjust(4, '0')
        words[:birth_month] = produced.born_at.month.to_s.rjust(2, '0')
        words[:birth_day]   = produced.born_at.day.to_s.rjust(2, '0')
        words[:birth_month_name] = 'date.month_names'.t[produced.born_at.month]
        words[:birth_day_name]   = 'date.day_names'.t[produced.born_at.wday]
        words[:birth_month_abbr] = 'date.abbr_month_names'.t[produced.born_at.month]
        words[:birth_day_abbr]   = 'date.abbr_day_names'.t[produced.born_at.wday]
      end
      text = reference.default_name.dup.gsub(/\{\{\w+\}\}/) do |key|
        words[key[2..-3]]
      end
    end
    text
  end

  # Define if the cast is valid for run
  def runnable?
    return true
    if reference.parted?
      if reference.known_variant?
        return quantity.present?
      else
        return (self.variant && quantity.present?)
      end
    elsif reference.produced?
      return self.variant
    elsif reference.type_variant?
      return self.variant
    else
      return product
    end
    false
  end

  def units_selector_list
    options = self.reference.handlers.map do |handler|
      if handler.population?
        [Onoma::Unit.find(:unity).human_name, handler.name]
      elsif handler.widget == :number
        unit = handler.unit? ? handler.unit : Onoma::Unit.find(:unity)
        ["#{unit.symbol} (#{handler.human_name})", handler.name]
      else
        fail "Cannot handler #{handler.widget} handlers"
      end
    end
  end

  def relevant_usage
    reference_data['usage'].present? ? InterventionParameter::LoggedPhytosanitaryUsage.new(reference_data['usage']) : usage
  end

  private def handle_working_zone_attributes
    nullify_working_zone_if_working_zone_area
    set_working_zone_area_from_working_zone
    set_quantity_from_working_zone
  end

  private def nullify_working_zone_if_working_zone_area
    if will_save_change_to_working_zone_area_value? && !will_save_change_to_working_zone?
      self.working_zone = nil
    end
  end

  private def set_working_zone_area_from_working_zone
    return nil if working_zone.nil? || !will_save_change_to_working_zone?

    self.working_zone_area_value = working_zone&.area&.in_square_meter&.in(DEFAULT_WORKING_ZONE_AREA_UNIT)&.value
  end

  private def set_quantity_from_working_zone
    return nil if working_zone.nil? && working_zone_area_value.nil?

    area = working_zone&.area || working_zone_area&.in_square_meter&.value
    self.quantity_value = area
    self.quantity_unit_name = 'square_meter'
    self.quantity_indicator_name = 'net_surface_area'
  end
end
