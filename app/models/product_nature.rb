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
# == Table: product_natures
#
#  abilities_list            :text
#  active                    :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  custom_fields             :jsonb
#  derivative_of             :string
#  derivatives_list          :text
#  description               :text
#  evolvable                 :boolean          default(FALSE), not null
#  frozen_indicators_list    :text
#  id                        :integer          not null, primary key
#  imported_from             :string
#  linkage_points_list       :text
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  number                    :string           not null
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  population_counting       :string           not null
#  provider                  :jsonb
#  reference_name            :string
#  subscribing               :boolean          default(FALSE), not null
#  subscription_days_count   :integer          default(0), not null
#  subscription_months_count :integer          default(0), not null
#  subscription_nature_id    :integer
#  subscription_years_count  :integer          default(0), not null
#  type                      :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  variable_indicators_list  :text
#  variety                   :string           not null
#

class ProductNature < ApplicationRecord
  include Autocastable
  include Customizable
  include Importable
  include Providable
  include Categorizable

  VARIETIES_NATURES = {
    animal: %w[animal animal_group],
    article: %w[bacteria bioproduct equipment_part fungus matter preparation product product_group virus water],
    crop: %w[land_parcel_group plant],
    equipment: %w[equipment equipment_fleet],
    service: %w[electricity immatter property_title service],
    worker: %w[worker],
    zone: %w[building zone]
  }.freeze

  VARIETIES_SUB_NATURES = {
    fertilizer: %w[compost guano liquid_slurry manure slurry],
    seed_and_plant: %w[seed seedling]
  }.freeze

  refers_to :variety
  refers_to :derivative_of, class_name: 'Variety'
  enumerize :population_counting, in: %i[unitary integer decimal], predicates: { prefix: true }
  enumerize :type, in: %w[Animal Article Crop Equipment Service Worker Zone].map { |t| "VariantTypes::#{t}Type" }
  belongs_to :subscription_nature
  has_many :subscriptions, through: :subscription_nature
  has_many :products, foreign_key: :nature_id, dependent: :restrict_with_exception
  has_many :variants, class_name: 'ProductNatureVariant', foreign_key: :nature_id, inverse_of: :nature, dependent: :restrict_with_exception
  has_one :default_variant, -> { order(:id) }, class_name: 'ProductNatureVariant', foreign_key: :nature_id

  has_picture

  serialize :abilities_list, WorkingSet::AbilityArray
  serialize :derivatives_list, SymbolArray
  serialize :frozen_indicators_list, SymbolArray
  serialize :variable_indicators_list, SymbolArray
  serialize :linkage_points_list, SymbolArray

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :abilities_list, :derivatives_list, :description, :frozen_indicators_list, :linkage_points_list, :variable_indicators_list, length: { maximum: 500_000 }, allow_blank: true
  validates :active, :evolvable, :subscribing, inclusion: { in: [true, false] }
  validates :name, presence: true, length: { maximum: 500 }
  validates :number, presence: true, uniqueness: true, length: { maximum: 500 }
  validates :picture_content_type, :picture_file_name, :reference_name, length: { maximum: 500 }, allow_blank: true
  validates :picture_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :picture_updated_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :population_counting, :variety, presence: true
  # ]VALIDATORS]
  validates :number, length: { allow_nil: true, maximum: 30 }
  validates :derivative_of, :reference_name, :variety, length: { allow_nil: true, maximum: 120 }
  validates :number, uniqueness: true
  validates :name, uniqueness: true
  validates_attachment_content_type :picture, content_type: /image/
  validates :subscription_nature, presence: { if: :subscribing? }

  accepts_nested_attributes_for :variants, reject_if: :all_blank, allow_destroy: true

  acts_as_numbered

  scope :availables, -> { where(active: true).order(:name) }
  scope :storage, -> { of_expression('can store(matter) or can store_liquid or can store_fluid or can store_gaz') }
  scope :identifiables, -> { of_variety(:animal) + select(&:population_counting_unitary?) }
  scope :services, -> { of_variety(:service) }
  scope :tools, -> { of_variety(:equipment) }

  # scope :producibles, -> { where(:variety => ["bos", "animal", "plant", "organic_matter"]).order(:name) }
  scope :of_type, ->(nature) { where(type: "VariantTypes::#{nature.to_s.capitalize}Type") }
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

  # Use working set query language to filter product nature
  scope :of_expression, ->(expression) { where(WorkingSet.to_sql(expression)) }

  protect(on: :destroy) do
    variants.any? || products.any?
  end

  before_validation do
    self.variety ||= derivative_of if derivative_of
    self.derivative_of = nil if self.variety.to_s == derivative_of.to_s
    # unless self.indicators_array.detect{|i| i.name.to_sym == :population}
    #   self.indicators ||= ""
    #   self.indicators << " population"
    # end
    # self.indicators = self.indicators_array.map(&:name).sort.join(", ")
    # self.abilities_list = self.abilities_list.sort.join(", ")
    self.subscription_years_count ||= 0
    self.subscription_months_count ||= 0
    self.subscription_days_count ||= 0
    self.type ||= "VariantTypes::#{find_nature&.capitalize}Type"
  end

  validate do
    if subscribing
      if self.subscription_years_count.zero? && self.subscription_months_count.zero? && self.subscription_days_count.zero?
        errors.add(:subscription_months_count, :invalid)
      end
    end
    if variety && variants.any?
      if variants.detect { |p| Onoma::Variety.find(p.variety) > variety }
        errors.add(:variety, :invalid)
      end
    end
    if derivative_of && variants.any?
      if variants.detect { |p| p.derivative_of? && Onoma::Variety.find(p.derivative_of) > derivative_of }
        errors.add(:derivative_of, :invalid)
      end
    end
  end

  def find_nature
    VARIETIES_NATURES.detect { |_k, v| v.include? Onoma::Variety.parent_variety(variety) }&.first
  end

  def identifiable?
    of_variety?(:animal) || population_counting_unitary?
  end

  def has_indicator?(indicator)
    indicators_list.include? indicator
  end

  # Permit to check WSQL expression "locally" to ensure performance
  def of_expression(expression)
    WorkingSet.check_record(expression, self)
  end

  # Returns the closest matching model based on the given variety
  def self.matching_model(variety)
    if item = Onoma::Variety.find(variety)
      item.self_and_parents.each do |ancestor|
        next unless model = begin
                              ancestor.name.camelcase.constantize
                            rescue
                              nil
                            end
        return model if model <= Product
      end
    end
    nil
  end

  # Returns the matching model for the record
  def matching_model
    self.class.matching_model(self.variety)
  end

  # Returns if population is frozen
  def population_frozen?
    population_counting_unitary?
  end

  # Returns the minimum couting element
  def population_modulo
    (population_counting_decimal? ? 0.0001 : 1)
  end

  # Returns list of all indicators
  def indicators
    (frozen_indicators + variable_indicators)
  end

  # Returns list of all indicators names
  def indicators_list
    (frozen_indicators_list + variable_indicators_list)
  end

  # Returns list of froezen indicators as an array of indicator items from the nomenclature
  def frozen_indicators
    frozen_indicators_list.collect { |i| Onoma::Indicator[i] }.compact
  end

  # Returns list of variable indicators as an array of indicator items from the nomenclature
  def variable_indicators
    variable_indicators_list.collect { |i| Onoma::Indicator[i] }.compact
  end

  # Returns list of indicators as an array of indicator items from the nomenclature
  def indicators_related_to(aspect)
    indicators.select { |i| i.related_to == aspect }
  end

  # Returns whole indicators
  def whole_indicators
    indicators_related_to(:whole)
  end

  # Returns whole indicator names
  def whole_indicators_list
    whole_indicators.map { |i| i.name.to_sym }
  end

  # Returns individual indicators
  def individual_indicators
    indicators_related_to(:individual)
  end

  # Returns individual indicator names
  def individual_indicators_list
    individual_indicators.map { |i| i.name.to_sym }
  end

  # Returns list of abilities as an array of ability items from the nomenclature
  def abilities
    abilities_list.collect do |i|
      (Onoma::Ability[i.to_s.split(/\(/).first] ? i.to_s : nil)
    end.compact
  end

  def ability(name)
    abilities_list.select do |a|
      a.to_s.split(/\(/).first == name.to_s
    end
  end

  def able_to?(ability)
    of_expression("can #{ability}")
  end

  # tests if all abilities are present
  # @params: *abilities, a list of abilities to check. Can't be empty
  # @returns: true if all abilities are matched, false if at least one ability is missing
  def able_to_each?(abilities)
    of_expression(abilities.map { |a| "can #{a}" }.join(' and '))
  end

  # Returns list of abilities as an array of ability items from the nomenclature
  def linkage_points
    linkage_points_list
  end

  def picture_path(style = :original)
    picture.path(style)
  end

  # Return humanized duration
  def subscription_duration
    l = []
    l << 'x_years'.tl(count: self.subscription_years_count) if self.subscription_years_count > 0
    l << 'x_months'.tl(count: self.subscription_months_count) if self.subscription_months_count > 0
    l << 'x_days'.tl(count: self.subscription_days_count) if self.subscription_days_count > 0
    l.to_sentence
  end

  # Compute stopped_on date from a started_on date for subsrbing product nature
  def subscription_stopped_on(started_on)
    stopped_on = started_on
    stopped_on += self.subscription_years_count.years
    stopped_on += self.subscription_months_count.months
    stopped_on += self.subscription_days_count.months
    stopped_on -= 1.day if stopped_on > started_on
    stopped_on
  end

  def compatible_dimensions
    Unit::STOCK_INDICATOR_PER_DIMENSION.select { |_k, v| frozen_indicators_list.include?(v.to_sym) }.keys.push(:none)
  end

  class << self
    # Returns some nomenclature items are available to be imported, e.g. not
    # already imported
    def any_reference_available?
      Onoma::ProductNature.without(ProductNature.pluck(:reference_name).uniq).any?
    end

    Item = Struct.new(:name, :variety, :derivative_of, :abilities_list, :indicators, :frozen_indicators, :variable_indicators)

    # Returns core attributes of nomenclature merge with nature if necessary
    # name, variety, derivative_of, abilities
    def flattened_nomenclature
      @flattened_nomenclature ||= Onoma::ProductNature.list.collect do |item|
        f = (item.frozen_indicators || []).map(&:to_sym)
        v = (item.variable_indicators || []).map(&:to_sym)
        Item.new(
          item.name,
          Onoma::Variety.find(item.variety),
          Onoma::Variety.find(item.derivative_of),
          WorkingSet::AbilityArray.load(item.abilities),
          f + v, f, v
        )
      end
    end

    # Lists ProductNature::Item which match given expression
    # Fully compatible with WSQL
    def items_of_expression(expression)
      flattened_nomenclature.select do |item|
        WorkingSet.check_record(expression, item)
      end
    end

    # Load a product nature from product nature nomenclature
    def import_from_nomenclature(reference_name, force = false)
      unless item = Onoma::ProductNature.find(reference_name)
        raise ArgumentError.new("The product nature #{reference_name.inspect} is unknown")
      end

      natures = ProductNature.where(reference_name: reference_name)

      return natures.first if !force && natures.count > 0

      nature_name = if force && natures.count > 0
                      item.human_name + "(#{natures.count.to_s})"
                    else
                      item.human_name
                    end

      nature = new(
        variety: item.variety,
        derivative_of: item.derivative_of.to_s,
        name: nature_name,
        population_counting: item.population_counting,
        reference_name: item.name,
        abilities_list: WorkingSet::AbilityArray.load(item.abilities),
        derivatives_list: (item.derivatives ? item.derivatives.sort : nil),
        frozen_indicators_list: (item.frozen_indicators ? item.frozen_indicators.sort : nil),
        variable_indicators_list: (item.variable_indicators ? item.variable_indicators.sort : nil),
        active: true,
        type: item.nature == :fee_and_service ? 'VariantTypes::ServiceType' : "VariantTypes::#{item.nature.capitalize}Type",
        imported_from: 'Nomenclature'
      )
      nature.linkage_points_list = item.linkage_points if item.linkage_points
      unless nature.save
        raise "Cannot import nature #{reference_name.inspect}: #{nature.errors.full_messages.join(', ')}"
      end

      nature
    end

    def import_from_lexicon(reference_name, force = false)
      unless item = MasterVariantNature.find_by(reference_name: reference_name)
        raise ArgumentError.new("The product nature #{reference_name.inspect} is unknown")
      end

      natures = ProductNature.where(reference_name: reference_name)

      return natures.first if !force && natures.count > 0

      nature_name = if force && natures.count > 0
                      item.translation.send(Preference[:language]) + "(#{natures.count.to_s})"
                    elsif ProductNature.where(name: item.translation.send(Preference[:language])).count > 0
                      item.translation.send(Preference[:language]) + "(#{natures.count.to_s})"
                    else
                      item.translation.send(Preference[:language])
                    end

      nature = new(
        variety: item.variety,
        derivative_of: item.derivative_of,
        name: nature_name,
        population_counting: item.population_counting,
        reference_name: item.reference_name,
        abilities_list: item.abilities,
        frozen_indicators_list: item.frozen_indicators.presence,
        variable_indicators_list: item.variable_indicators.presence,
        active: true,
        type: "VariantTypes::#{item.family.classify}Type",
        imported_from: 'Lexicon'
      )
      unless nature.save
        raise "Cannot import nature #{reference_name.inspect}: #{nature.errors.full_messages.join(', ')}"
      end

      nature
    end

    def load_defaults(**_options)
      MasterVariantNature.find_each do |nature|
        import_from_lexicon(nature.reference_name)
      end
    end

    def import_all_from_nomenclature
      Onoma::ProductNature.find_each do |product_nature|
        import_from_nomenclature(product_nature.name)
      end
    end

    private

      def retrieve_indicators(variant_nature)
        if variant_nature.population_counting_decimal?
          frozen_indicators = %i[net_mass net_volume].select { |i| variant_nature.indicators.map(&:to_sym).include?(i) }
          variable_indicators = variant_nature.indicators.map(&:to_sym) - %i[net_mass net_volume]
          { frozen: frozen_indicators, variable: variable_indicators }
        else
          { frozen: [], variable: variant_nature.indicators.map(&:to_sym) }
        end
      end
  end
end
