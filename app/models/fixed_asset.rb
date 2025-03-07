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
# == Table: fixed_assets
#
#  accounted_at                        :datetime
#  allocation_account_id               :integer
#  asset_account_id                    :integer
#  ceded                               :boolean
#  ceded_on                            :date
#  created_at                          :datetime         not null
#  creator_id                          :integer
#  currency                            :string           not null
#  current_amount                      :decimal(19, 4)
#  custom_fields                       :jsonb
#  depreciable_amount                  :decimal(19, 4)   not null
#  depreciated_amount                  :decimal(19, 4)   not null
#  depreciation_fiscal_coefficient     :decimal(, )
#  depreciation_method                 :string           not null
#  depreciation_percentage             :decimal(19, 4)
#  depreciation_period                 :string
#  description                         :text
#  expenses_account_id                 :integer
#  id                                  :integer          not null, primary key
#  journal_entry_id                    :integer
#  journal_id                          :integer          not null
#  lock_version                        :integer          default(0), not null
#  name                                :string           not null
#  number                              :string           not null
#  pretax_selling_amount               :decimal(19, 4)
#  product_id                          :integer
#  provider                            :jsonb
#  purchase_amount                     :decimal(19, 4)
#  purchase_id                         :integer
#  purchase_item_id                    :integer
#  purchased_on                        :date
#  sale_id                             :integer
#  sale_item_id                        :integer
#  scrapped_journal_entry_id           :integer
#  scrapped_on                         :date
#  selling_amount                      :decimal(19, 4)
#  sold_journal_entry_id               :integer
#  sold_on                             :date
#  special_imputation_asset_account_id :integer
#  started_on                          :date             not null
#  state                               :string
#  stopped_on                          :date
#  tax_id                              :integer
#  updated_at                          :datetime         not null
#  updater_id                          :integer
#  waiting_asset_account_id            :integer
#  waiting_journal_entry_id            :integer
#  waiting_on                          :date
#

class FixedAsset < ApplicationRecord
  include Attachable
  include Customizable
  include Transitionable
  include Providable

  bookkeep # This callback permits to add journal entry corresponding to the fixed asset when entering in use
  acts_as_numbered

  enumerize :depreciation_method, in: %i[linear regressive none], predicates: { prefix: true } # graduated
  enumerize :depreciation_period, in: %i[monthly quarterly yearly], default: -> { Preference.get(:default_depreciation_period).value || Preference.set!(:default_depreciation_period, :yearly, :string) }
  enumerize :state, in: %i[draft waiting in_use sold scrapped], predicates: true, i18n_scope: "models.#{model_name.param_key}.states"
  refers_to :currency

  belongs_to :journal, class_name: 'Journal'
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :scrapped_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :sold_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :waiting_journal_entry, class_name: 'JournalEntry', dependent: :destroy

  belongs_to :allocation_account, class_name: 'Account'
  belongs_to :asset_account, class_name: 'Account'
  belongs_to :expenses_account, class_name: 'Account'
  belongs_to :special_imputation_asset_account, class_name: 'Account'
  belongs_to :waiting_asset_account, class_name: 'Account'

  belongs_to :activity
  belongs_to :product
  belongs_to :tax
  belongs_to :sale
  belongs_to :sale_item
  has_many :purchase_items, inverse_of: :fixed_asset
  has_many :depreciations, -> { order(:position) }, dependent: :destroy, class_name: 'FixedAssetDepreciation' do
    def following(depreciation)
      where('position > ?', depreciation.position)
    end
  end
  has_many :planned_depreciations, -> { order(:position).where('NOT locked OR accounted_at IS NULL') }, class_name: 'FixedAssetDepreciation', dependent: :destroy

  has_many :parcel_items, through: :purchase_item
  has_many :delivery_products, through: :parcel_items, source: :product
  has_one :tool, class_name: 'Equipment'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :ceded, inclusion: { in: [true, false] }, allow_blank: true
  validates :ceded_on, :purchased_on, :scrapped_on, :sold_on, :waiting_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }, allow_blank: true
  validates :currency, :depreciation_method, :journal, presence: true
  validates :current_amount, :depreciation_percentage, :pretax_selling_amount, :purchase_amount, :selling_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :depreciable_amount, :depreciated_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :depreciation_fiscal_coefficient, numericality: true, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, :number, presence: true, length: { maximum: 500 }
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :stopped_on, timeliness: { on_or_after: ->(fixed_asset) { fixed_asset.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }, allow_blank: true
  # ]VALIDATORS]
  validates :name, uniqueness: true
  validates :asset_account, presence: true
  validates :currency, match: { with: :journal, to_invalidate: :journal }
  validates :depreciation_fiscal_coefficient, presence: true, if: -> { depreciation_method_regressive? }
  validates :depreciation_method, inclusion: { in: depreciation_method.values }
  validates :tax_id, :selling_amount, :pretax_selling_amount, presence: { if: :sold? }

  validates :scrapped_on, financial_year_writeable: { if: -> { scrapped_on } }
  validates :scrapped_on, timeliness: { on_or_after: ->(fixed_asset) { fixed_asset.started_on }, on_or_before: -> { Date.today }, type: :date }, if: -> { scrapped_on }
  validates :scrapped_on, :product_id, presence: true, on: :scrap
  validates :sold_on, financial_year_writeable: { if: -> { sold_on } }
  validates :sold_on, :product_id, presence: true, on: :sell
  validates :sold_on, timeliness: { on_or_after: ->(fixed_asset) { fixed_asset.started_on }, on_or_before: -> { Date.today }, type: :date }, if: -> { sold_on }
  validates :stopped_on, :allocation_account, :expenses_account, presence: { unless: :depreciation_method_none? }
  validates :waiting_on, timeliness: { on_or_before: ->(fixed_asset) { fixed_asset.started_on }, type: :date }, if: -> { waiting_on }, allow_blank: true
  validates :waiting_on, presence: true, financial_year_writeable: true, on: :stand_by
  validates :depreciable_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :started_on, ongoing_exchanges: true

  scope :drafts, -> { where(state: %w[draft]) }
  scope :draft_or_waiting, -> { where(state: %w[draft waiting]) }
  scope :used, -> { where(state: %w[in_use]) }
  scope :sold_or_scrapped, -> { where(state: %w[sold scrapped]) }
  scope :start_before, ->(date) { where('fixed_assets.started_on <= ?', date) }
  scope :not_linked_to_sale, -> { used.where(sale_id: nil, sale_item_id: nil) }

  # [DEPRECATIONS[
  #  - purchase_id
  #  - purchase_item_id
  # ]DEPRECATIONS]

  def self.state_machine(*args)
    ActiveSupport::Deprecation.warn "Not used anymore on FixedAsset!"
    nil
  end

  after_initialize do
    next if persisted?

    @auto_depreciate = true

    self.currency ||= Preference[:currency]
    self.depreciated_amount ||= 0
    self.state ||= :draft
  end

  before_validation do
    self.depreciation_period ||= Preference.get(:default_depreciation_period)
    self.depreciation_period ||= Preference.set!(:default_depreciation_period, :yearly, :string)
    self.depreciation_percentage = 20 if depreciation_percentage.blank? || depreciation_percentage <= 0
    self.purchase_amount ||= depreciable_amount
    self.purchased_on ||= started_on
    set_stopped_on
    true
  end

  validate on: :create do
    errors.add :base, :no_opened_financial_year if FinancialYear.opened.count == 0
  end

  validate on: :scrap do
    if product && scrapped_on
      if product.born_at > scrapped_on
        errors.add(:scrapped_on, :on_or_after_field, attribute: I18n.translate('attributes.scrapped_on'),
                   restriction: product.born_at.to_date.l,
                   field: I18n.translate('activerecord.attributes.equipment.born_at'),
                   model: product.name)
      end

      last_used_at = product.interventions.maximum(:stopped_at)
      if last_used_at && last_used_at > scrapped_on
        errors.add(:scrapped_on, :used_in_intervention, attribute: I18n.translate('attributes.scrapped_on'),
                   restriction: last_used_at.to_date.l,
                   model: product.name)
      end
    end
  end

  validate on: :sell do
    if product && sold_on
      if product.born_at > sold_on
        errors.add(:sold_on, :on_or_after_field, attribute: I18n.translate('attributes.sold_on'),
                   restriction: product.born_at.to_date.l,
                   field: I18n.translate('activerecord.attributes.equipment.born_at'),
                   model: product.name)
      end

      last_used_at = product.interventions.maximum(:stopped_at)
      if last_used_at && last_used_at > sold_on
        errors.add(:sold_on, :used_in_intervention, attribute: I18n.translate('attributes.sold_on'),
                   restriction: last_used_at.to_date.l,
                   model: product.name)
      end
    end
  end

  validate do
    if started_on && stopped_on && stopped_on < started_on
      errors.add(:stopped_on, :posterior, to: started_on.l)
    end
    true
  end

  before_update do
    @auto_depreciate = false
    # if no depreciations present, then generate it
    @auto_depreciate = true if self.depreciations.count == 0
    # if important attr change,regenerate depreciation
    old = self.class.find(id)
    %i[depreciable_amount started_on stopped_on depreciation_method
       depreciation_period depreciation_percentage currency].each do |attr|
      @auto_depreciate = true if send(attr) != old.send(attr)
    end
  end

  after_save do
    # if purchase_item
    # Link products to fixed asset
    # delivery_products.each do |product|
    # product.fixed_asset = self
    # unless product.save
    #  Rails.logger.warn('Cannot link fixed_asset to its products automatically')
    # end
    # end
    # end
    depreciate! if @auto_depreciate
    sale.update_columns(invoiced_at: sold_on.to_datetime) if saved_changes[:sold_on] && sale && !sale.invoice? && sold_on
  end

  after_update do
    if in_use? && product && !product.used_in_interventions_before(started_on)
      product.update!(born_at: started_on.to_datetime)
    end
  end

  protect on: :update do
    return true if (old_record.scrapped? || old_record.sold?)

    if depreciations.any?(&:locked_or_journal_entry_confirmed?) || (journal_entry && journal_entry.confirmed?)
      AUTHORIZED_COLUMNS = %w[product_id sale_id sale_item_id tax_id selling_amount pretax_selling_amount sold_on scrapped_on updater_id updated_at state].freeze
      (changes_to_save.keys - AUTHORIZED_COLUMNS).any?
    else
      false
    end
  end

  protect on: :destroy do
    (waiting? && waiting_journal_entry&.confirmed?) || (in_use? && journal_entry&.confirmed?) || scrapped? || sold? || !depreciations.all?(&:destroyable?)
  end

  def set_stopped_on
    return if %w[sold scrapped].include?(state)

    if depreciation_method_linear?
      if started_on
        months = 12 * (100.0 / depreciation_percentage.to_f)
        self.stopped_on = started_on + months.floor.months
        self.stopped_on += (months - months.floor) * 30.0 - 1
      end
    end
    if depreciation_method_regressive?
      self.depreciation_fiscal_coefficient ||= 1.75
      if started_on
        months = 12 * (100.0 / depreciation_percentage.to_f)
        self.stopped_on = started_on >> months.floor
        self.stopped_on += (months - months.floor) * 30.0 - 1
      end
    end
  end

  def on_unclosed_periods?
    started_on > journal.closed_on
  end

  def status
    return :go if in_use?
    return :caution if draft? || waiting?
    return :stop if scrapped? || sold?
  end

  def add_amount(amount)
    unless depreciations.any?(&:journal_entry)
      update!(purchase_amount: purchase_amount + amount, depreciable_amount: depreciable_amount + amount)
    end
  end

  def update_amounts
    unless depreciations.any?(&:journal_entry)
      amount = purchase_items.map(&:pretax_amount).sum
      update(purchase_amount: amount, depreciable_amount: amount)
    end
  end

  def round(amount)
    currency.to_currency.round amount
  end

  def opened_financial_year?
    FinancialYear.on(started_on)&.opened?
  end

  def started_during_financial_year_closure_preparation?
    FinancialYear.on(started_on)&.closure_in_preparation?
  end

  def depreciate!
    planned_depreciations.clear

    # Computes periods
    unless depreciation_method_none?
      fy_reference = FinancialYear.at(started_on) || FinancialYear.opened.first

      depreciation_start = started_on
      depreciation_start = started_on.beginning_of_month if depreciation_method == :regressive

      periods = DepreciationCalculator.new(fy_reference, depreciation_period.to_sym).depreciation_period(depreciation_start, depreciation_percentage)
      total_duration = periods.sum(&:last)
      case depreciation_method
      when 'linear'
        depreciate_with_linear_method(periods, total_duration)
      when 'regressive'
        depreciate_with_regressive_method(periods, total_duration)
      else
        raise StandardError.new("Invalid depreciation method: #{depreciation_method}")
      end
    end

    self
  end

  # Depreciate using linear method
  # Years have 12 months with 30 days
  def depreciate_with_linear_method(periods, depreciable_days)
    self.reload
    dep_amount = self.depreciable_amount
    # case of depreciations (locked or accounted) exists.
    # recompute depreciable_days and depreciable_amount
    depreciations.each do |dep|
      depreciable_days -= dep.duration
      dep_amount -= dep.amount
    end

    # remaining amount to distribute into depreciations
    remaining_amount = dep_amount.to_d
    position = 1
    # for each period, check if theres a depreciations (locked or accounted) or create it
    periods.each_with_index do |period, index|
      next if remaining_amount <= 0

      start = period[0]
      # take end of month for clean and bookkeeped depreciations
      # take last date if > fixed asset stopped_on
      if period[1] > stopped_on
        stop = stopped_on
      elsif period[1].end_of_month > stopped_on
        stop = period[1]
      else
        stop = period[1].end_of_month
      end
      depreciation = depreciations.on(start).first
      unless depreciation
        depreciation = depreciations.new(started_on: start, stopped_on: stop)
        duration = depreciation.duration
        # round cents for the last depreciation by getting the previous depreciable_amount
        if periods[index + 1].nil?
          depreciation.amount = depreciations.up_to(start).reorder(:started_on).last.depreciable_amount
        else
          depreciation.amount = [remaining_amount, currency.to_currency.round(dep_amount * duration / depreciable_days)].min
        end
        remaining_amount -= depreciation.amount
      end
      depreciation.position = position
      position += 1
      depreciation.save!
      # depreciation.financial_year = FinancialYear.at(depreciation.started_on)
    end
  end

  # Depreciate using regressive method
  def depreciate_with_regressive_method(periods, _depreciable_days)
    self.reload
    depreciable_days = duration
    dep_amount = self.depreciable_amount
    reload.depreciations.each do |depreciation|
      depreciable_days -= depreciation.duration
      dep_amount -= depreciation.amount
    end

    remaining_days = depreciable_days
    regressive_depreciation_percentage = depreciation_percentage * depreciation_fiscal_coefficient

    ## Create it if not exists?
    remaining_amount = dep_amount.to_d
    position = 1

    periods.each_with_index do |period, index|
      next if periods[index + 1].nil? || remaining_amount <= 0

      start = period[0]
      stop = period[1]

      depreciation = depreciations.on(start).first
      unless depreciation
        depreciation = depreciations.new(started_on: start.beginning_of_month, stopped_on: stop.end_of_month)

        current_year = index
        if depreciation_period == :quarterly
          current_year /= 4
        elsif depreciation_period == :monthly
          current_year /= 12
        end

        remaining_linear_depreciation_percentage = (100 * depreciation_percentage / (100 - (current_year * depreciation_percentage))).round(2)
        percentage = [regressive_depreciation_percentage, remaining_linear_depreciation_percentage].max

        depreciation.amount = [remaining_amount, currency.to_currency.round(remaining_amount * (percentage / 100) * (depreciation.duration / 360))].min
        remaining_amount -= depreciation.amount
      end
      next if depreciation.amount.to_f == 0.0

      depreciation.position = position
      position += 1
      depreciation.save!
      remaining_days -= depreciation.duration
    end
  end

  def depreciable?
    depreciations.none?
  end

  # @param [Date] on
  # @return [FixedAssetDepreciation, nil]
  def depreciation_on(on)
    depreciations.where('? BETWEEN started_on AND stopped_on', on).reorder(:position).last
  end

  # return the current_depreciation at current date, nil if after or before the first depreciation
  #
  # @param [Date] on
  # @return [FixedAssetDepreciation, nil]
  def current_depreciation(on = Date.today)
    depreciation_on(on)
  end

  # return the net book value at current date
  #
  # @param [Date] on
  # @return [Numeric]
  def net_book_value(on = Date.today)
    if on < started_on
      depreciable_amount
    elsif (depreciation = current_depreciation(on)).present?
      depreciation.depreciated_amount
    else
      0
    end
  end

  # return the global amount already depreciated
  #
  # @param [Date] on
  # @return [Numeric]
  def already_depreciated_value(on = Date.today)
    if on < started_on
      0
    elsif (depreciation = current_depreciation(on)).present?
      depreciation.depreciated_amount
    else
      depreciable_amount
    end
  end

  # Returns the duration in days of all the depreciations
  def duration
    self.class.duration(started_on, self.stopped_on, mode: depreciation_method.to_sym)
  end

  def human_status
    I18n.t("tooltips.models.fixed_asset.#{state}")
  end

  # Returns the duration in days between to 2 times
  def self.duration(started_on, stopped_on, options = {})
    days = 0
    options[:mode] ||= :linear
    if options[:mode] == :linear
      sa = (started_on.day >= 30 || (started_on.end_of_month == started_on) ? 30 : started_on.day)
      so = (stopped_on.day >= 30 || (stopped_on.end_of_month == stopped_on) ? 30 : stopped_on.day)

      if started_on.beginning_of_month == stopped_on.beginning_of_month
        days = so - sa + 1
      else
        days = 30 - sa + 1
        cursor = started_on.beginning_of_month
        while (cursor >> 1) < stopped_on.beginning_of_month
          cursor = cursor >> 1
          days += 30
        end
        days += so
      end
    elsif options[:mode] == :regressive
      sa = (started_on.day >= 30 || (started_on.end_of_month == started_on) ? 30 : 1)
      so = (stopped_on.day >= 30 || (stopped_on.end_of_month == stopped_on) ? 30 : stopped_on.day)

      if started_on.beginning_of_month == stopped_on.beginning_of_month
        days = so - sa + 1
      else
        days = 30 - sa + 1
        cursor = started_on.beginning_of_month
        while (cursor >> 1) < stopped_on.beginning_of_month
          cursor = cursor >> 1
          days += 30
        end
        days += so
      end
    else
      raise "What ? #{options[:mode].inspect}"
    end
    days.to_f
  end
end
