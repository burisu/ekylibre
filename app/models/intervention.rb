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
# == Table: interventions
#
#  accounted_at                   :datetime
#  actions                        :string
#  auto_calculate_working_periods :boolean          default(FALSE)
#  costing_id                     :integer
#  created_at                     :datetime         not null
#  creator_id                     :integer
#  currency                       :string
#  custom_fields                  :jsonb
#  description                    :text
#  event_id                       :integer
#  id                             :integer          not null, primary key
#  issue_id                       :integer
#  journal_entry_id               :integer
#  lock_version                   :integer          default(0), not null
#  nature                         :string           not null
#  number                         :string
#  parent_id                      :integer
#  prescription_id                :integer
#  procedure_name                 :string           not null
#  provider                       :jsonb
#  providers                      :jsonb
#  purchase_id                    :integer
#  request_compliant              :boolean
#  request_intervention_id        :integer
#  started_at                     :datetime         not null
#  state                          :string           not null
#  stopped_at                     :datetime         not null
#  trouble_description            :text
#  trouble_encountered            :boolean          default(FALSE), not null
#  updated_at                     :datetime         not null
#  updater_id                     :integer
#  validator_id                   :integer
#  whole_duration                 :integer          not null
#  working_duration               :integer          not null
#

class Intervention < ApplicationRecord
  include CastGroupable
  include Customizable
  include PeriodicCalculable
  include Providable

  PLANNED_REALISED_ACCEPTED_GAP = { intervention_doer: 1.2, intervention_tool: 1.2, intervention_input: 1.2 }.freeze
  PHYTO_PROCEDURE_NAMES = %w[spraying all_in_one_sowing all_in_one_planting sowing_with_spraying vine_spraying_without_fertilizing vine_leaves_fertilizing vine_spraying_with_fertilizing chemical_mechanical_weeding vine_chemical_weeding vine_capsuls_dispersing].freeze
  SETTINGS = %i[spray_mix_volume_area_density].freeze
  SPRAYING_PROCEDURE_NAMES = %w[spraying sowing_with_spraying vine_spraying_without_fertilizing vine_spraying_with_fertilizing].freeze

  attr_readonly :procedure_name, :production_id, :currency
  refers_to :currency
  enumerize :procedure_name, in: Procedo.procedure_names, i18n_scope: ['procedures'], predicates: true, scope: true
  enumerize :nature, in: %i[request record], default: :record, predicates: true, scope: true
  enumerize :state, in: %i[in_progress done validated rejected], default: :done, predicates: true
  belongs_to :event, dependent: :destroy, inverse_of: :intervention
  belongs_to :request_intervention, -> { where(nature: :request) }, class_name: 'Intervention'
  belongs_to :issue
  belongs_to :prescription
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :purchase
  belongs_to :costing, class_name: 'InterventionCosting', dependent: :destroy
  belongs_to :validator, class_name: 'User', foreign_key: :validator_id
  belongs_to :intervention_proposal, class_name: 'InterventionProposal'
  has_many :receptions, class_name: 'Reception', dependent: :destroy
  has_many :labellings, class_name: 'InterventionLabelling', dependent: :destroy, inverse_of: :intervention
  has_many :labels, through: :labellings
  has_many :record_interventions, -> { where(nature: :record) }, class_name: 'Intervention', inverse_of: 'request_intervention', foreign_key: :request_intervention_id
  has_many :intervention_crop_groups, dependent: :destroy
  has_many :crop_groups, through: :intervention_crop_groups
  has_many :rides, dependent: :nullify
  has_many :parameter_settings, class_name: 'InterventionParameterSetting', dependent: :nullify
  has_many :parameter_setting_items, class_name: 'InterventionSettingItem', through: :parameter_settings, source: :settings
  has_many :settings, class_name: 'InterventionSettingItem', dependent: :destroy

  has_and_belongs_to_many :activities
  has_and_belongs_to_many :activity_productions
  has_and_belongs_to_many :campaigns

  with_options inverse_of: :intervention do
    has_many :participations, class_name: 'InterventionParticipation', dependent: :destroy
    has_many :root_parameters, -> { where(group_id: nil) }, class_name: 'InterventionParameter', dependent: :destroy
    has_many :parameters, class_name: 'InterventionParameter'
    has_many :group_parameters, -> { order(:position) }, class_name: 'InterventionGroupParameter'
    has_many :product_parameters, -> { order(:position) }, class_name: 'InterventionProductParameter'
    has_many :doers, class_name: 'InterventionDoer'
    has_many :inputs, class_name: 'InterventionInput'
    has_many :outputs, class_name: 'InterventionOutput'
    has_many :targets, class_name: 'InterventionTarget'
    has_many :tools, class_name: 'InterventionTool'
    has_many :working_periods, class_name: 'InterventionWorkingPeriod', dependent: :destroy
    has_many :leaves_parameters, -> { where.not(type: InterventionGroupParameter) }, class_name: 'InterventionParameter'
    has_many :agents, class_name: 'InterventionAgent'
  end
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :actions, :number, length: { maximum: 500 }, allow_blank: true
  validates :auto_calculate_working_periods, :request_compliant, inclusion: { in: [true, false] }, allow_blank: true
  validates :description, :trouble_description, length: { maximum: 500_000 }, allow_blank: true
  validates :nature, :procedure_name, :state, presence: true
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  validates :stopped_at, presence: true, timeliness: { on_or_after: ->(intervention) { intervention.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  validates :trouble_encountered, inclusion: { in: [true, false] }
  validates :whole_duration, :working_duration, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  # ]VALIDATORS]
  validates :actions, presence: true
  # validates_associated :group_parameters, :doers, :inputs, :outputs, :targets, :tools, :working_periods

  serialize :actions, SymbolArray

  alias_attribute :duration, :working_duration

  calculable period: :month, column: :working_duration, at: :started_at, name: :sum

  acts_as_numbered unless: :run_sequence

  before_validation :set_number, on: :create

  def set_number
    # planning
    if intervention_proposal.present? && !parent_id.present?
      self.number = intervention_proposal.number
    elsif request_intervention.present?
      self.number = request_intervention.number
    end
  end

  def run_sequence
    # planning
    (intervention_proposal.present? && !parent_id.present?) || request_intervention.present?
  end

  # Big hack to access private constant as it seems that HABTM classes are now private in Rails 5.0
  def self.habtm_activities
    HABTM_Activities
  end

  accepts_nested_attributes_for :group_parameters, :participations, :doers, :inputs, :outputs, :targets, :tools, :working_periods, :labellings, :intervention_crop_groups, :rides, :parameter_settings, allow_destroy: true
  accepts_nested_attributes_for :parameter_settings, reject_if: ->(params) do
    params["settings_attributes"].values.all? do |items|
      items['measure_value_value'].blank? && items['integer_value'].blank? && items['boolean_value'].blank? && items['decimal_value'].blank? && items['string_value'].blank?
    end
  end
  accepts_nested_attributes_for :settings, reject_if: ->(params) { params['measure_value_value'].blank? && params['integer_value'].blank? && params['boolean_value'].blank? && params['decimal_value'].blank? && params['string_value'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :receptions, reject_if: :all_blank, allow_destroy: true

  scope :between, lambda { |started_at, stopped_at|
    where(started_at: started_at..stopped_at)
  }

  scope :of_civil_year, lambda { |year|
    where('EXTRACT(YEAR FROM started_at) = ?', year)
  }

  scope :of_nature, ->(reference_name) { where(procedure_name: reference_name) }
  scope :of_nature_using_phytosanitary, -> { where(procedure_name: PHYTO_PROCEDURE_NAMES) }

  scope :of_category, lambda { |category|
    where(procedure_name: Procedo::Procedure.of_category(category).map(&:name))
  }
  scope :of_campaign, lambda { |campaign|
    where(id: HABTM_Campaigns.select(:intervention_id).where(campaign: campaign))
  }
  scope :of_campaigns, ->(*campaigns) {
    where(id: HABTM_Campaigns.select(:intervention_id).where(campaign: campaigns))
  }
  scope :of_current_campaigns, -> { of_campaign(Campaign.current) }
  scope :of_activity_production, lambda { |production|
    where(id: InterventionTarget.of_activity_production(production).select(:intervention_id))
  }
  scope :of_activity, lambda { |activity|
    where(id: InterventionTarget.of_activity(activity).select(:intervention_id))
  }
  scope :of_activities, lambda { |*activities|
    where(id: InterventionTarget.of_activities(activities.flatten))
  }

  scope :of_activity_family, ->(activity_family) {
    where(procedure_name: Procedo::Procedure.of_activity_family(activity_family).map(&:name))
  }

  scope :ordered_by, ->(by = :started_at) { reorder(by) }

  scope :provisional, -> { where('stopped_at > ?', Time.zone.now) }
  scope :real, -> { where(nature: :record).where('stopped_at <= ?', Time.zone.now) }

  scope :with_generic_cast, lambda { |role, object|
    where(id: InterventionProductParameter.of_generic_role(role).of_actor(object).select(:intervention_id))
  }

  scope :with_unroll, lambda { |*args|
    params = args.extract_options!.with_indifferent_access
    search_params = []

    if params[:q].present?
      procedures = Procedo.selection.select { |l, _n| l.downcase.include? params[:q].strip }.map { |_l, n| "'#{n}'" }.join(',')

      search_params << if procedures.empty?
                         "#{Intervention.table_name}.number ILIKE '%#{params[:q]}%'"
                       else
                         "(#{Intervention.table_name}.number ILIKE '%#{params[:q]}%' OR #{Intervention.table_name}.procedure_name IN (#{procedures}))"
                       end
    end

    # CAUTION: params[:nature] is not used as in controller list filter
    if params[:nature].present?
      search_params << "#{Intervention.table_name}.nature = '#{params[:nature]}'"
      if params[:nature] == :request
        search_params << "#{Intervention.table_name}.state != '#{Intervention.state.rejected}' AND I.request_intervention_id IS NULL"
      end
    end

    if params[:state].present? && params[:nature] != :request
      search_params << "#{Intervention.table_name}.state = '#{params[:state]}'"
    end

    if params[:cultivable_zone_id].present?
      search_params << "#{Intervention.table_name}.id IN (SELECT intervention_id FROM activity_productions_interventions INNER JOIN #{ActivityProduction.table_name} ON #{ActivityProduction.table_name}.id = activity_production_id INNER JOIN #{CultivableZone.table_name} ON #{CultivableZone.table_name}.id = #{ActivityProduction.table_name}.cultivable_zone_id WHERE #{CultivableZone.table_name}.id = '#{params[:cultivable_zone_id]}')"
    end

    if params[:procedure_name_id].present?
      search_params << "#{Intervention.table_name}.procedure_name = '#{params[:procedure_name_id]}'"
    end

    if params[:activity_id].present?
      search_params << "#{Intervention.table_name}.id IN (SELECT intervention_id FROM interventions INNER JOIN activities_interventions ON activities_interventions.intervention_id = interventions.id INNER JOIN activities ON activities.id = activities_interventions.activity_id WHERE activities.id = '#{params[:activity_id]}')"
    end

    if params[:target_id].present?
      search_params << "#{Intervention.table_name}.id IN (SELECT intervention_id FROM intervention_parameters WHERE product_id = '#{params[:target_id]}')"
    end

    if params[:worker_id].present?
      search_params << "#{Intervention.table_name}.id IN (SELECT intervention_id FROM interventions INNER JOIN #{InterventionDoer.table_name} ON #{InterventionDoer.table_name}.intervention_id = #{Intervention.table_name}.id WHERE #{InterventionDoer.table_name}.product_id = '#{params[:worker_id]}')"
    end

    if params[:equipment_id].present?
      search_params << "#{Intervention.table_name}.id IN (SELECT intervention_id FROM interventions INNER JOIN #{InterventionParameter.table_name} ON #{InterventionParameter.table_name}.intervention_id = #{Intervention.table_name}.id WHERE #{InterventionParameter.table_name}.product_id = '#{params[:equipment_id]}')"
    end

    unless params[:period_interval].blank? && params[:period].blank?

      period_interval = params[:period_interval].to_sym
      period = params[:period]

      if period_interval == :day
        search_params << "EXTRACT(DAY FROM #{Intervention.table_name}.started_at) = #{period.to_date.day} AND EXTRACT(MONTH FROM #{Intervention.table_name}.started_at) = #{period.to_date.month} AND EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = #{period.to_date.year}"
      end

      if period_interval == :week
        beginning_of_week = period.to_date.at_beginning_of_week.to_time.beginning_of_day
        end_of_week = period.to_date.at_end_of_week.to_time.end_of_day
        search_params << "#{Intervention.table_name}.started_at >= '#{beginning_of_week}' AND #{Intervention.table_name}.stopped_at <= '#{end_of_week}'"
      end

      if period_interval == :month
        search_params << "EXTRACT(MONTH FROM #{Intervention.table_name}.started_at) = #{period.to_date.month} AND EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = #{period.to_date.year}"
      end

      if period_interval == :year
        search_params << "EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = #{period.to_date.year}"
      end
    end

    page = params[:page]
    page ||= 1

    request = where(search_params.join(' AND '))
                .joins('LEFT OUTER JOIN interventions I ON interventions.id = I.request_intervention_id')
                .includes(:doers)
                .includes(:targets)
                .references(product_parameters: [:product])
                .order(started_at: :desc)

    { total_count: request.count, interventions: request.page(page) }
  }

  scope :with_targets, ->(*targets) { where(id: InterventionTarget.of_actors(targets).select(:intervention_id)) }
  scope :with_outputs, ->(*outputs) { where(id: InterventionOutput.of_actors(outputs).select(:intervention_id)) }
  scope :with_doers, ->(*doers) { where(id: InterventionDoer.of_actors(doers).select(:intervention_id)) }
  scope :with_input_of_maaids, ->(*maaids) { where(id: InterventionInput.of_maaids(*maaids).pluck(:intervention_id)) }
  scope :with_input_presence, -> { where(id: InterventionInput.all.pluck(:intervention_id).uniq) }
  scope :without_input_presence, -> { where.not(id: InterventionInput.all.pluck(:intervention_id).uniq) }
  scope :without_output_presence, -> { where.not(id: InterventionOutput.all.pluck(:intervention_id).uniq) }
  scope :done, -> {}

  before_validation do
    self.trouble_encountered ||= false
    if working_periods.any? && !working_periods.detect { |p| p.started_at.blank? || p.stopped_at.blank? }
      self.started_at = working_periods.map(&:started_at).min
      self.stopped_at = working_periods.map(&:stopped_at).max
      self.working_duration = working_periods.map { |p| p.stopped_at - p.started_at }.sum.to_i
      self.whole_duration = (stopped_at - started_at).to_i
    end
    if started_at && stopped_at
      self.whole_duration = (stopped_at - started_at).to_i
    end
    self.currency ||= Preference[:currency]
    self.state ||= self.class.state.default_value
    if procedure
      if actions && actions.empty?
        self.actions = if procedure.mandatory_actions.any?
                         procedure.mandatory_actions.map(&:name)
                       else
                         procedure.optional_actions.map(&:name)
                       end
      end
    end
    if receptions.any?
      receptions.each { |reception| reception.given_at = working_periods.first.started_at }
    end
    true
  end

  validate do
    if procedure
      all_known = actions.all? { |action| procedure.has_action?(action) }
      errors.add(:actions, :invalid) unless all_known
    end

    if started_at && stopped_at && stopped_at <= started_at
      errors.add(:stopped_at, :posterior, to: started_at.l)
    end

    if printed_on
      errors.add(:printed_on, :not_opened_financial_year) if Preference[:permanent_stock_inventory] && !during_financial_year?
    end

    errors.add(:base, :financial_year_exchange_on_this_period) if during_financial_year_exchange? && (inputs.any? || outputs.any?) && Preference[:permanent_stock_inventory]
  end

  before_save do
    columns = { name: name, started_at: started_at, stopped_at: stopped_at, nature: :production_intervention }

    if event
      # self.event.update_columns(columns)
      event.attributes = columns
    else
      event = Event.create!(columns)
      # self.update_column(:event_id, event.id)
      self.event_id = event.id
    end

    true
  end

  after_save do
    # planning
    if %w[done validated].include?(state) && intervention_proposal.present? && nature != 'request'
      itinerary_template = intervention_proposal.technical_itinerary_intervention_template
      intervention_proposals = intervention_proposal
                                .activity_production
                                .intervention_proposals
                                .joins(:technical_itinerary_intervention_template)
                                .where("technical_itinerary_intervention_templates.position > ?", itinerary_template.position)
                                .of_batch_number(intervention_proposal.batch_number)
                                .of_irregulat_batch(intervention_proposal.irregular_batch)
                                .order('technical_itinerary_intervention_templates.position')

      date = started_at
      intervention_proposals.each do |ip|
        date += ip.technical_itinerary_intervention_template.day_between_intervention.day
        ip.update(estimated_date: date)
      end
    end
    # puts self.inspect.green
    targets.find_each do |target|
      if target.new_container_id
        ProductLocalization.find_or_create_by(product: target.product, container: Product.find(target.new_container_id), intervention_id: target.intervention_id, started_at: working_periods.maximum(:stopped_at))
      end

      if target.new_group_id
        ProductMembership.find_or_create_by(member: target.product, group: Product.find(target.new_group_id), intervention_id: target.intervention_id, started_at: working_periods.maximum(:stopped_at))
      end

      if target.new_variant_id
        ProductPhase.find_or_create_by(product: target.product, variant: ProductNatureVariant.find(target.new_variant_id), intervention_id: target.intervention_id, started_at: working_periods.maximum(:stopped_at))
      end

      if target.identification_number && target.product.identification_number.nil?
        target.update_column :identification_number, target.identification_number
      end
    end

    participations.update_all(state: state) unless state == :in_progress
    participations.update_all(request_compliant: request_compliant) if request_compliant

    update_costing

    add_activity_production_to_output if procedure.of_category?(:planting)

    reconcile_receptions

    # refresh view
    WorkerTimeIndicator.refresh
  end

  after_save :handle_targets_imputation_ratio
  after_commit :compute_pfi_async

  after_create do
    Ekylibre::Hook.publish :create_intervention, self
  end

  # Prevents from deleting an intervention that was executed
  protect on: :destroy do
    with_undestroyable_products?
  end

  # This method permits to add stock journal entries corresponding to the
  # interventions which consume or produce products.
  # It depends on the preferences which permit to activate the "permanent stock
  # inventory" and "automatic bookkeeping".
  #
  # | Interv. mode | Debit                     | Credit                    |
  # | outputs      | stock (3X)                | stock_movement (603X/71X) |
  # | inputs       | stock_movement (603X/71X) | stock (3X)                |
  bookkeep do |b|
    if Preference[:permanent_stock_inventory]
      stock_journal = Journal.find_by(nature: :various, used_for_permanent_stock_inventory: true)
      # HACK: adding other code choices instead of properly addressing the problem
      # of code collision
      unless stock_journal
        stock_journal_name = [:stocks.tl, :inventory.tl].find do |name|
          !Journal.find_by(name: name)
        end
        stock_journal = Journal.new(name: stock_journal_name, nature: :various, used_for_permanent_stock_inventory: true).tap(&:valid?)

        [stock_journal.code, :STOC, :IVNT].each do |new_code|
          conflicting_journals = Journal.where(code: new_code)
          next if conflicting_journals.any?

          stock_journal.code = new_code
          break if stock_journal.save
        end
        raise "Couldn't create stock journal for permanent inventory bookkeeping" unless stock_journal && stock_journal.persisted?
      end
    end

    b.journal_entry(stock_journal, printed_on: printed_on, if: (Preference[:permanent_stock_inventory] && record?)) do |entry|
      write_parameter_entry_items = lambda do |parameter, input|
        variant = parameter.variant
        stock_amount = parameter.stock_amount.round(2) if parameter.stock_amount
        next unless parameter.product_movement && stock_amount.nonzero? && variant.storable?

        label = tc(:bookkeep, resource: name, name: parameter.product.name)
        debit_account = input ? variant.stock_movement_account_id : variant.stock_account_id
        credit_account = input ? variant.stock_account_id : variant.stock_movement_account_id
        entry.add_debit(label, debit_account, stock_amount, as: (input ? :stock_movement : :stock))
        entry.add_credit(label, credit_account, stock_amount, as: (input ? :stock : :stock_movement))
      end
      inputs.each { |input| write_parameter_entry_items.call(input, true) }
      outputs.each { |output| write_parameter_entry_items.call(output, false) }
    end
  end

  def update_costing
    attributes = {}

    %i[input tool doer].each do |type|
      attributes["#{type.to_s.pluralize}_cost"] = cost(type) || 0
    end
    attributes[:receptions_cost] = receptions_cost.to_f.round(2)

    if costing
      costing.update(attributes)
    else
      update_columns(costing_id: InterventionCosting.create!(attributes).id)
    end
  end

  def compare_planned_and_realised
    return :no_request if request_intervention.nil? || request_intervention.parameters.blank?
    return false if request_intervention.duration != self.duration

    accepted_error = PLANNED_REALISED_ACCEPTED_GAP
    params_result = true

    associations = %i[doers tools inputs targets]
    associations.each do |association|
      self_parameters = send(association)
      request_parameters = request_intervention.send(association)
      if (self_parameters.empty? && request_parameters.any?) || (self_parameters.any? && request_parameters.empty?)
        params_result = false
        break false
      end
      unless self_parameters.empty? && request_parameters.empty?
        if self_parameters.group_by(&:product_id).count != request_parameters.group_by(&:product_id).count
          params_result = false
          break false
        end
        request_parameters.group_by(&:product_id).each do |product_id, request_param|
          self_param = product_parameters.where(product_id: product_id)

          return false if self_param.empty?

          # For InterventionDoer and InterventionTool
          request_duration = 0
          request_param.each { |param| request_duration += calculate_cost_amount_computation(param).quantity }

          self_duration = 0
          self_param.each { |param| self_duration += calculate_cost_amount_computation(param).quantity }

          percent = accepted_error[request_param.first.type.underscore.to_sym] || 1.2
          intervals = (request_duration / percent..request_duration * percent)

          unless intervals.include?(self_duration)
            params_result = false
            break false
          end
          # For InterventionTarget
          if self_param.map(&:working_zone).compact.sum != request_param.map(&:working_zone).compact.sum
            params_result = false
            break false
          end

          # For InterventionInput
          request_quantity = request_param.map(&:quantity_population).compact.sum
          self_quantity = self_param.map(&:quantity_population).compact.sum

          percent = accepted_error[request_param.first.type.underscore.to_sym] || 1.2
          intervals = (request_quantity / percent..request_quantity * percent)
          unless intervals.include?(self_quantity)
            params_result = false
            break false
          end
        end
      end
    end
    params_result
  end

  def calculate_cost_amount_computation(product_parameter)
    if product_parameter.product.is_a?(Worker)
      computation = product_parameter.cost_amount_computation
    elsif product_parameter.product.try(:tractor?) && product_parameter.try(:participation) && product_parameter.participation.present?
      computation = product_parameter.cost_amount_computation(natures: %i[travel intervention])
    else
      computation = product_parameter.cost_amount_computation(natures: %i[intervention])
    end
    computation
  end

  def create_missing_costing
    update_costing if costing.blank?
  end

  def initialize_record(state: :done)
    raise 'Can only generate record for an intervention request' unless request?
    return record_interventions.first if record_interventions.any?

    new_record = deep_clone(
      only: %i[auto_calculate_working_periods actions custom_fields description event_id issue_id
               nature number prescription_id procedure_name
               request_intervention_id started_at state
               stopped_at trouble_description trouble_encountered
               whole_duration working_duration],
      include:
        [
          { group_parameters: :parameters },
          :working_periods,
          :root_parameters
        ],
      use_dictionary: true
    ) do |original, kopy|
      kopy.intervention_id = nil if original.respond_to? :intervention_id
    end
    new_record.request_intervention_id = id
    new_record.nature = :record
    new_record.state = state
    new_record
  end

  def printed_at
    (stopped_at? ? stopped_at : created_at? ? created_at : Time.zone.now)
  end

  def printed_on
    printed_at.to_date
  end

  def during_financial_year?
    FinancialYear.opened.where('? BETWEEN started_on AND stopped_on', printed_at).any?
  end

  def with_undestroyable_products?
    outputs.includes(:product).map(&:product).detect do |product|
      next unless product

      InterventionProductParameter.of_actor(product).where.not(type: 'InterventionOutput').any?
    end
  end

  # planning
  def missing_parameters
    required_parameters = procedure.required_product_parameters
    required_parameters_infos = required_parameters.map do |param|
      reference_name = param.name.to_s
      type = param.type.to_s.pluralize
      has_group_parameter = param.group.name != :root_
      { reference_name: reference_name, type: type, has_group_parameter: has_group_parameter }
    end

    intervention_parameters_infos = decorate.parameters_infos
    missing_parameters = []
    required_parameters_infos.each do |req_param|
      next if intervention_parameters_infos.include?(req_param.except(:has_group_parameter))

      missing_parameters << req_param
    end
    missing_parameters
  end

  # Returns human activity names
  def human_activities_names
    activities.map(&:name).to_sentence
  end

  # The Procedo::Procedure behind intervention
  def procedure
    Procedo.find(procedure_name)
  end

  # Deprecated method to return procedure
  def reference
    ActiveSupport::Deprecation.warn 'Intervention#reference is deprecated.' \
                                    'Please use Intervention#procedure instead.'
    procedure
  end

  def targets_list
    targets.includes(:product).map(&:product).compact.map(&:work_name).sort
  end

  # Returns human target names
  def human_target_names
    targets_list.to_sentence
  end

  # Returns human doer names
  def human_doer_names
    doers.map(&:product).compact.map(&:work_name).sort.to_sentence
  end

  # Returns human tool names
  def human_tool_names
    tools.map(&:product).compact.map(&:work_name).sort.to_sentence
  end

  # Returns human inputs names and quantity
  def human_input_quantity_names
    names = []
    inputs.each do |input|
      names << "#{input.name} : #{input.human_quantity}"
    end
    names.sort.to_sentence
  end

  # Returns human actions names
  def human_actions_names
    actions.map { |action| Onoma::ProcedureAction.find(action).human_name }
      .to_sentence
  end

  def name
    # raise self.inspect if self.procedure_name.blank?
    tc(:name, intervention: (procedure ? procedure.human_name : "procedures.#{procedure_name}".t(default: procedure_name.humanize)), number: number)
  end

  def start_time
    started_at
  end

  def human_working_duration(unit = :hour)
    working_duration.in(:second).convert(unit).round(2).l(precision: 2)
  end

  def working_duration_of_nature(nature = :intervention)
    InterventionWorkingPeriod.of_intervention_participations(InterventionParticipation.of_intervention(self)).of_nature(nature).sum(:duration)
  end

  def completely_filled?
    reference_names = parameters.pluck(:reference_name).uniq
    reference_names = reference_names.map(&:to_sym)
    parameters_names = procedure.parameters.map(&:name).uniq

    result = parameters_names - reference_names | reference_names - parameters_names
    result.empty?
  end

  # Update temporality informations in intervention
  def update_temporality
    reload unless new_record? || destroyed?

    if working_periods.any?
      started_at = working_periods.minimum(:started_at)
      stopped_at = working_periods.maximum(:stopped_at)
      update_columns(
        started_at: started_at,
        stopped_at: stopped_at,
        working_duration: working_periods.sum(:duration),
        whole_duration: (stopped_at && started_at ? (stopped_at - started_at).to_i : 0)
      )
    end

    if event
      event.update_columns(
        started_at: self.started_at,
        stopped_at: self.stopped_at
      )
    end

    outputs.find_each do |output|
      product = output.product
      next unless product

      product.born_at = self.started_at
      product.initial_born_at = product.born_at
      product.save!

      reading = product.initial_reading(:shape)
      unless reading.nil?
        reading.read_at = product.born_at
        reading.save!
      end

      movement = output.product_movement
      next unless movement

      movement.started_at = self.started_at
      movement.stopped_at = self.stopped_at
      movement.save!
    end

    inputs.find_each do |input|
      product = input.product
      next unless product

      movement = input.product_movement
      next unless movement

      movement.started_at = self.started_at
      movement.stopped_at = self.stopped_at
      movement.save!
    end
  end

  # Sums all intervention product parameter total_cost of a particular role
  def cost(role = :input)
    params = product_parameters.of_generic_role(role)

    if params.any?
      return params.map(&:cost).compact.sum if participations.empty?

      return params.map do |param|
        natures = {}
        if param.product.is_a?(Equipment)
          natures = %i[travel intervention] if param.product.try(:tractor?)
          natures = %i[intervention] unless param.product.try(:tractor?)
        end

        param.cost(natures: natures)
      end.compact.sum
    end

    nil
  end

  def receptions_cost
    receptions.any? ? receptions.sum(:pretax_amount) : 0
  end

  def cost_per_area(role = :input, area_unit = :hectare)
    zone_area = working_zone_area(area_unit).to_f.round(2)
    if zone_area > 0.0
      params = product_parameters.of_generic_role(role)
      costs = params.map(&:cost).compact
      return (costs.sum / zone_area) * area_cost_coefficient if costs.any?

      nil
    end
    nil
  end

  def total_cost
    %i[input tool doer].map do |type|
      (cost(type) || 0.0).to_d
    end.sum + receptions_cost
  end

  def human_total_cost
    total_cost.round(Onoma::Currency.find(currency).precision)
  end

  def total_cost_per_area(area_unit = :hectare)
    zone_area = working_zone_area(area_unit).to_f
    (total_cost / zone_area) * area_cost_coefficient if zone_area > 0.0
  end

  def area_cost_coefficient
    zone_area = working_zone_area(:hectare).to_f.round(2)
    global_area = activity_production_zone_area(:hectare).to_f.round(2)
    coef = 1.0
    # build coef for area's
    if zone_area && global_area && global_area > 0.0
      coef = zone_area / global_area
    end
    coef
  end

  def currency
    Preference[:currency]
  end

  def earn(role = :output)
    params = product_parameters.of_generic_role(role)
    return params.map(&:earn).compact.sum if params.any?

    nil
  end

  # return all working zone area of targets
  def working_zone_area(*args)
    options = args.extract_options!
    unit = args.shift || options[:unit] || :hectare
    area = if targets.any?
             targets.with_working_zone_area.map(&:working_area).sum.in(unit)
           else
             0.0.in(unit)
           end
    area
  end

  # return all initial area of supports of targets
  def activity_production_zone_area(*args)
    options = args.extract_options!
    unit = args.shift || options[:unit] || :hectare
    if targets.any?
      ap = ActivityProduction.where(id: targets.map{ |p| p.product.activity_production_id})
      area = ap.map(&:support_shape_area).sum.in(:square_meter).convert(unit)
    end
    area ||= 0.0.in(unit)
    area
  end

  def human_working_zone_area(*args)
    options = args.extract_options!
    unit = args.shift || options[:unit] || :hectare
    precision = args.shift || options[:precision] || 2
    working_zone_area(unit: unit).round(precision).l(precision: precision)
  end

  def human_activity_production_zone_area(*args)
    options = args.extract_options!
    unit = args.shift || options[:unit] || :hectare
    precision = args.shift || options[:precision] || 2
    activity_production_zone_area(unit: unit).round(precision).l(precision: precision)
  end

  def working_area(unit = :hectare)
    ActiveSupport::Deprecation.warn 'Intervention#working_area is deprecated. Please use Intervention#working_zone_area instead.'
    working_zone_area(unit)
  end

  def spray_mix_volume_area_density
    global_volume_area_indicator = self.settings.find_by(indicator_name: 'spray_mix_volume_area_density')
    if spraying? && global_volume_area_indicator.present?
      global_volume_area_indicator.value
    else
      nil
    end
  end

  def activity_imputation(activity)
    if activity.size_indicator == :net_surface_area
      unit = :hectare
      precision = 2
      if targets.any?
        at = targets.of_activity(activity).with_working_zone_area.map(&:working_area).sum.in(unit)
        coeff = (at.to_d / working_zone_area.to_d) if working_zone_area.to_d != 0.0
        return nil unless coeff

        coeff.round(precision)
      end
    end
  end

  def status
    return :caution if in_progress? || request?
    return :go if done? || validated?
    return :stop if rejected?
  end

  def human_status
    state_label
  end

  # Prints human name of current state
  def state_label
    translation_key =
    if request?
      "request"
    elsif in_progress?
      "in_progress"
    elsif done? || validated?
      "done"
    else
      "rejected"
    end

    I18n.t("tooltips.models.intervention.#{translation_key}")
  end

  def runnable?
    return false unless record? && procedure

    valid = true
    # Check cardinality and runnability
    procedure.parameters.each do |parameter|
      all_parameters = parameters.where(reference_name: parameter.name)
      # unless parameter.cardinality.include?(parameters.count)
      #   valid = false
      # end
      all_parameters.each do |parameter|
        valid = false unless parameter.runnable?
      end
    end
    valid
  end

  def add_activity_production_to_output
    parameters = group_parameters

    group_parameters.each do |group_parameter|
      activity_production_id = group_parameter
                                 .targets
                                 .map(&:product)
                                 .flatten
                                 .map(&:activity_production_id)
                                 .uniq
                                 .first

      products_to_update = group_parameter
                             .outputs
                             .map(&:product)
                             .flatten
                             .uniq

      products_to_update.each do |product|
        product.update(activity_production_id: activity_production_id)
      end
    end
  end

  def receptions_is_given?
    return receptions.first.given? if receptions.any?

    false
  end

  # Run the intervention ie. the state is marked as done
  # Returns intervention
  # DEPRECATED Will be removed in 3.0
  def run!
    ActiveSupport::Deprecation.warn 'Intervention#run! is deprecated, because it never works. Use classical AR methods instead to create interventions'
    raise 'Cannot run intervention without procedure' unless runnable?

    update_attributes(state: :done)
    self
  end

  def add_working_period!(started_at, stopped_at)
    working_periods.create!(started_at: started_at, stopped_at: stopped_at)
  end

  def update_state(modifier = {})
    return unless participations.any? || modifier.present?

    states = participations.pluck(:id, :state).to_h
    states[modifier.keys.first] = modifier.values.first
    update(state: :in_progress) if states.values.map(&:to_sym).index(:in_progress)
    update(state: :done) if (states.values.map(&:to_sym) - [:done]).empty?
  end

  def update_compliance(modifier = {})
    return unless participations.any? || !modifier.nil?

    compliances = participations.pluck(:id, :request_compliant).to_h
    compliances[modifier.keys.first] = modifier.values.first
    update(request_compliant: false) if compliances.values.index(false)
    update(request_compliant: true) if (compliances.values - [true]).empty?
  end

  def participation(product)
    InterventionParticipation.of_intervention(self).of_product(product).first
  end

  def worker_working_periods(nature: nil, not_nature: nil, worker_id: nil)
    workers_participations = participations.select { |participation| participation.product.is_a?(Worker) }
    if worker_id
      workers_participations = workers_participations.select { |participation| participation.product_id = worker_id }
    end
    working_periods = nil

    if nature.nil? && not_nature.nil?
      working_periods = workers_participations.map(&:working_periods)
    elsif !nature.nil?
      working_periods = workers_participations.map { |participation| participation.working_periods.where(nature: nature) }
    elsif !not_nature.nil?
      working_periods = workers_participations.map { |participation| participation.working_periods.where.not(nature: not_nature) }
    end

    working_periods.flatten
  end

  def drivers_times(nature: nil, not_nature: nil)
    worker_working_periods(nature: nature, not_nature: not_nature)
      .map(&:duration)
      .reduce(0, :+)
  end

  def first_worker_working_period(nature: nil, not_nature: nil)
    test = worker_working_periods(nature: nature, not_nature: not_nature)
  end

  # compute stopped_at and duration if not present and if duration <
  def duration_from_catalog
    flows = InterventionModel.where(procedure_reference: procedure_name, working_flow_unit: 'ha/h')
    inverse_speed = flows.average(:working_flow)
    if inverse_speed.to_d > 0.0 && working_zone_area.to_f > 0.0
      real_stop = started_at + (inverse_speed.to_d * working_zone_area.to_d * 3600)
      catalog_duration = (real_stop - started_at).in(:second).convert(:hour)
    end
  end

  def build_duplicate_intervention_attributes
    associations_parameters = { intervention: {} }
    %w[targets tools inputs doers outputs participations working_periods].each do |product_parameter|
      next unless self.send(product_parameter).any?

      key = (product_parameter + '_attributes').to_sym
      associations_parameters[:intervention][key] = {}
      self.send(product_parameter).each_with_index do |parameter, parameter_index|
        parameter_attributes = build_has_many_association(product_parameter, parameter)
        associations_parameters[:intervention][key][parameter_index] = parameter_attributes
      end
    end

    if self.group_parameters.any?
      associations_group_parameters = { intervention: { group_parameters_attributes: {} } }
      self.group_parameters.each_with_index do |gp, gp_index|
        associations_group_parameters[:intervention][:group_parameters_attributes][gp_index] = { reference_name: gp.reference_name }
        %w[targets tools inputs doers outputs].each do |product_parameter|
          next unless gp.send(product_parameter).any?

          key = (product_parameter + '_attributes').to_sym
          associations_group_parameters[:intervention][:group_parameters_attributes][gp_index][key] = {}
          gp.send(product_parameter).each_with_index do |parameter, parameter_index|
            parameter_attributes = build_has_many_association(product_parameter, parameter)
            associations_group_parameters[:intervention][:group_parameters_attributes][gp_index][key][parameter_index] = parameter_attributes
          end
        end
      end
      associations_parameters.deep_merge!(associations_group_parameters)
    end

    parameters = self.attributes.merge(associations_parameters)
    parameters
  end

  def build_has_many_association(product_parameter, parameter)
    if product_parameter == 'inputs'
      parameter_attributes = { product_id: parameter.product_id.to_s, reference_name: parameter.reference_name, quantity_value: parameter.quantity_value, quantity_handler: parameter.quantity_handler, quantity_population: parameter.quantity_population }
    elsif product_parameter == 'outputs'
      parameter_attributes = { variant_id: parameter.variant_id.to_s, reference_name: parameter.reference_name, quantity_value: parameter.quantity_value, quantity_handler: parameter.quantity_handler, quantity_population: parameter.quantity_population }
    elsif product_parameter == 'participations'
      parameter_attributes = { product_id: parameter.product_id, state: parameter.state, working_periods_attributes: [] }
      parameter.working_periods.each_with_index do |wp, wp_index|
        wp_attributes = { nature: wp.nature, started_at: wp.started_at, stopped_at: wp.stopped_at }
        parameter_attributes[:working_periods_attributes][wp_index] = wp_attributes
      end
    elsif product_parameter == 'working_periods'
      parameter_attributes = { started_at: parameter.started_at, stopped_at: parameter.stopped_at }
    elsif product_parameter == 'targets'
      parameter_attributes = { product_id: parameter.product_id.to_s, reference_name: parameter.reference_name, working_zone: parameter.working_zone }
    else
      parameter_attributes = { product_id: parameter.product_id.to_s, reference_name: parameter.reference_name }
    end
    parameter_attributes
  end

  def max_non_treatment_area
    inputs.map(&:non_treatment_area).compact.max
  end

  def using_phytosanitary?
    PHYTO_PROCEDURE_NAMES.include?(procedure_name)
  end

  def spraying?
    SPRAYING_PROCEDURE_NAMES.include?(procedure_name)
  end

  # @private
  # Lifecycle: called after save
  private def reconcile_receptions
    receptions.each do |reception|
      reception.update(reconciliation_state: 'reconcile') if reception.reconciliation_state != 'reconcile'
    end
  end

  private def compute_pfi_async
    return if !eligible_for_pfi_calculation?

    campaign = Campaign.find_by(harvest_year: started_at.year)

    PfiCalculationJob.perform_later(campaign, [self], creator)
  end

  # @private
  # Lifecycle: called after save
  private def handle_targets_imputation_ratio
    targets.reload
    total_targets_quantity = if targets.any?(&:working_zone_area_value)
                               targets.where.not(working_zone_area_value: nil).sum(:working_zone_area_value)
                             else
                               targets.where(working_zone_area_value: nil).count
                             end

    targets.find_each do |target|
      target.update_imputation_ratio(total_targets_quantity)
    end
  end

  private def during_financial_year_exchange?
    FinancialYearExchange.opened.at(printed_at).exists?
  end

  private def eligible_for_pfi_calculation?
    using_phytosanitary? && inputs.any?
  end

  class << self
    def used_procedures
      select(:procedure_name).distinct.pluck(:procedure_name).map do |name|
        Procedo.find(name)
      end.compact
    end

    # Create and run intervention
    def run!(*args)
      attributes = args.extract_options!
      attributes[:procedure_name] ||= args.shift
      intervention = transaction do
        intervention = Intervention.create!(attributes)
        yield intervention if block_given?
        intervention.run!
      end
      intervention
    end

    # Registers and runs an intervention directly
    def write(*args)
      options = args.extract_options!
      procedure_name = args.shift || options[:procedure_name]

      transaction do
        attrs = options.slice(:procedure_name, :description, :issue_id, :prescription_id)
        recorder = Intervention::Recorder.new(attrs)

        yield recorder

        recorder.write!
      end
    end

    # Find a product with given options
    #  - started_at
    #  - work_number
    #  - can
    #  - variety
    #  - derivative_of
    #  - filter: WSQL expression
    # Options for product creation only:
    #  - default_storage
    # Special options for worker creation only:
    #  - first_name
    #  - last_name
    #  - born_at
    #  - default_storage
    def find_products(model, options = {})
      relation = model
      relation = relation.where('COALESCE(born_at, ?) <= ? ', options[:started_at], options[:started_at]) if options[:started_at]
      relation = relation.of_expression(options[:filter]) if options[:filter]
      relation = relation.of_work_numbers(options[:work_number]) if options[:work_number]
      relation = relation.can(options[:can]) if options[:can]
      relation = relation.of_variety(options[:variety]) if options[:variety]
      relation = relation.derivative_of(options[:derivative_of]) if options[:derivative_of]
      return relation.all if relation.any?
    end

    # Returns an array of procedures matching the given actors ordered by relevance
    # whose structure is [[procedure, relevance, arity], [procedure, relevance, arity], ...]
    # where 'procedure' is a Procedo::Procedure object, 'relevance' is a float,
    # 'arity' is the number of actors matched in the procedure
    # ==== parameters:
    #   - actors, an array of actors identified for a given procedure
    # ==== options:
    #   - relevance: sets the relevance threshold above which results are wished.
    #     A float number between 0 and 1 is expected. Default value: 0.
    #   - limit: sets the number of wanted results. By default all results are returned
    #   - history: sets the use of actors history to calculate relevance.
    #     A boolean is expected. Default: false,since checking through history is slower
    #   - provisional: sets the use of actors provisional to calculate relevance.
    #     A boolean is expected. Default: false, since it's slower.
    #   - max_arity: limits results to procedures matching most actors.
    #     A boolean is expected. Default: false
    def match(actors, options = {})
      actors = [actors].flatten
      limit = options[:limit].to_i - 1
      relevance_threshold = options[:relevance].to_f
      maximum_arity = 0

      # Creating coefficients for relevance calculation for each procedure
      # coefficients depend on provisional, actors history and actors presence in procedures
      history = Hash.new(0)
      provisional = []
      actors_id = []
      actors_id = actors.map(&:id) if options[:history] || options[:provisional]

      # Select interventions from all actors history
      if options[:history]
        # history is considered relevant on 1 year
        history.merge!(Intervention.joins(:product_parameters)
                         .where("intervention_parameters.actor_id IN (#{actors_id.join(', ')})")
                         .where(started_at: (Time.zone.now.midnight - 1.year)..(Time.zone.now))
                         .group('interventions.procedure_name')
                         .count('interventions.procedure_name'))
      end

      if options[:provisional]
        provisional.concat(Intervention.distinct
                             .joins(:product_parameters)
                             .where("intervention_parameters.actor_id IN (#{actors_id.join(', ')})")
                             .where(started_at: (Time.zone.now.midnight - 1.day)..(Time.zone.now + 3.days))
                             .pluck('interventions.procedure_name')).uniq!
      end

      coeff = {}

      history_size = 1.0 # prevents division by zero
      history_size = history.values.reduce(:+).to_f if history.count >= 1

      denominator = 1.0
      denominator += 2.0 if options[:history] && history.present?
      denominator += 3.0 if provisional.present? # if provisional is empty, it's pointless using it for relevance calculation

      result = []
      Procedo.procedures do |procedure_key, procedure|
        coeff[procedure_key] = 1.0 + 2.0 * (history[procedure_key].to_f / history_size) + 3.0 * provisional.count(procedure_key).to_f
        matched_parameters = procedure.matching_parameters_for(actors)
        if matched_parameters.any?
          result << [procedure, (((matched_parameters.values.count.to_f / actors.count) * coeff[procedure_key]) / denominator), matched_parameters.values.count]
          maximum_arity = matched_parameters.values.count if maximum_arity < matched_parameters.values.count
        end
      end
      result.delete_if { |_procedure, relevance, _arity| relevance < relevance_threshold }
      result.delete_if { |_procedure, _relevance, arity| arity < maximum_arity } if options[:max_arity]
      result.sort_by { |_procedure, relevance, _arity| -relevance }[0..limit]
    end

    def convert_to_purchase(interventions)
      purchase = nil
      transaction do
        interventions = interventions
                          .collect { |intv| (intv.is_a?(self) ? intv : find(intv)) }
                          .sort_by(&:stopped_at)
        planned_at = interventions.last.stopped_at
        owners = interventions.map(&:doers).map { |t| t.map(&:product).map(&:owner).compact }.flatten.uniq
        supplier = owners.first if owners.second.blank?
        unless nature = PurchaseNature.actives.first
          unless journal = Journal.purchases.opened_at(planned_at).first
            raise 'No purchase journal'
          end

          nature = PurchaseNature.new(
            active: true,
            journal: journal,
            by_default: true,
            name: PurchaseNature.tc('default.name', default: PurchaseNature.model_name.human)
          )
        end
        purchase = nature.purchases.new(
          supplier: supplier,
          planned_at: planned_at,
          delivery_address: supplier && supplier.default_mail_address,
          description: %(#{Intervention.model_name.plural.tl}:
\t- #{interventions.map(&:name).join("\n\t - ")})
        )

        # Adds items
        interventions.each do |intervention|
          hourly_params = {
            catalog: Catalog.by_default!(:cost),
            quantity_method: ->(_item) { intervention.duration.in_second.in_hour }
          }
          components = {
            doers: hourly_params,
            tools: hourly_params,
            inputs: {
              catalog: Catalog.by_default!(:purchase),
              quantity_method: ->(item) { item.quantity }
            }
          }

          components.each do |component, cost_params|
            intervention.send(component).each do |item|
              catalog_item = Maybe(cost_params[:catalog].items.find_by(variant_id: item.variant))
              quantity = cost_params[:quantity_method].call(item).round(3)
              purchase.items.new(
                variant: item.variant,
                unit_pretax_amount: catalog_item.pretax_amount.or_else(nil),
                tax: catalog_item.reference_tax.or_else(nil),
                quantity: quantity.value.to_f,
                annotation: %(#{Intervention.model_name.human} '#{intervention.name}' > \
                #{Intervention.human_attribute_name(component).capitalize}
                \t- #{item.product.name} x #{quantity.l(precision: 2)})
              )
            end
          end
        end
      end
      purchase
    end

    def convert_to_sale(interventions)
      sale = nil
      transaction do
        interventions = interventions
                          .collect { |intv| (intv.is_a?(self) ? intv : find(intv)) }
                          .sort_by(&:stopped_at)
        planned_at = interventions.last.stopped_at

        owners = interventions.map do |intervention|
          intervention.targets.map do |target|
            if target.product.is_a?(LandParcel)
              prod = target.activity_production
              owner = prod && prod.cultivable_zone && prod.cultivable_zone.farmer
            elsif target.product.is_a?(Equipment)
              owner = target.product.owner
            end
            owner
          end
        end
        owners = owners.flatten.uniq
        client = owners.first unless owners.count > 1
        unless nature = SaleNature.actives.first
          unless journal = Journal.sales.opened_at(planned_at).first
            raise 'No sale journal'
          end

          nature = SaleNature.new(
            active: true,
            currency: Preference[:currency],
            journal: journal,
            by_default: true,
            name: SaleNature.tc('default.name', default: SaleNature.model_name.human)
          )
        end
        sale = nature.sales.new(
          client: client,
          address: client && client.default_mail_address,
          description: %(#{Intervention.model_name.plural.tl}:
\t- #{interventions.map(&:name).join("\n\t - ")})
        )
        # Adds items
        interventions.each do |intervention|
          hourly_params = {
            catalog: Catalog.by_default!(:cost),
            quantity_method: ->(_item) { intervention.duration.in_second.in_hour }
          }
          components = {
            doers: hourly_params,
            tools: hourly_params,
            inputs: {
              catalog: Catalog.by_default!(:sale),
              quantity_method: ->(item) { item.quantity }
            }
          }

          components.each do |component, cost_params|
            intervention.send(component).each do |item|
              catalog_item = Maybe(cost_params[:catalog].items.find_by(variant_id: item.variant))
              quantity = cost_params[:quantity_method].call(item).round(3)
              sale.items.new(
                variant: item.variant,
                unit_pretax_amount: catalog_item.pretax_amount.or_else(nil),
                tax: catalog_item.reference_tax.or_else(nil),
                quantity: quantity.value.to_f,
                annotation: %(#{Intervention.model_name.human} '#{intervention.name}' > \
                #{Intervention.human_attribute_name(component).capitalize}
                \t- #{item.product.name} x #{quantity.l(precision: 2)})
              )
            end
          end
        end
      end
      sale
    end
  end
end
