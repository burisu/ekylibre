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
# == Table: journal_entries
#
#  absolute_credit            :decimal(19, 4)   default(0.0), not null
#  absolute_currency          :string           not null
#  absolute_debit             :decimal(19, 4)   default(0.0), not null
#  balance                    :decimal(19, 4)   default(0.0), not null
#  continuous_number          :integer
#  created_at                 :datetime         not null
#  creator_id                 :integer
#  credit                     :decimal(19, 4)   default(0.0), not null
#  currency                   :string           not null
#  debit                      :decimal(19, 4)   default(0.0), not null
#  financial_year_exchange_id :integer
#  financial_year_id          :integer
#  id                         :integer          not null, primary key
#  journal_id                 :integer          not null
#  lock_version               :integer          default(0), not null
#  number                     :string           not null
#  printed_on                 :date             not null
#  provider                   :jsonb
#  real_balance               :decimal(19, 4)   default(0.0), not null
#  real_credit                :decimal(19, 4)   default(0.0), not null
#  real_currency              :string           not null
#  real_currency_rate         :decimal(19, 10)  default(0.0), not null
#  real_debit                 :decimal(19, 4)   default(0.0), not null
#  reference_number           :string
#  resource_id                :integer
#  resource_prism             :string
#  resource_type              :string
#  state                      :string           not null
#  updated_at                 :datetime         not null
#  updater_id                 :integer
#  validated_at               :datetime
#

# There is 3 types of set of values (debit, credit...). These types
# corresponds to the 3 currency we always add in accountancy:
#  - *          in journal currency
#  - real_*     in financial year currency
#  - absolute_* in global currency (the same as current financial year's theoretically)
class JournalEntry < ApplicationRecord
  class IncompatibleCurrencies < StandardError; end

  include Attachable
  include ComplianceCheckable
  attr_readonly :journal_id
  refers_to :currency
  refers_to :real_currency, class_name: 'Currency'
  refers_to :absolute_currency, class_name: 'Currency'
  belongs_to :financial_year
  belongs_to :journal, inverse_of: :entries
  belongs_to :resource, polymorphic: true
  belongs_to :financial_year_exchange, inverse_of: :journal_entries
  has_many :affairs, dependent: :nullify
  has_many :fixed_asset_depreciations, dependent: :nullify
  has_many :useful_items, -> { where('balance != ?', 0.0) }, foreign_key: :entry_id, class_name: 'JournalEntryItem'
  has_many :items, foreign_key: :entry_id, dependent: :delete_all, class_name: 'JournalEntryItem', inverse_of: :entry do
    def credit
      where('credit > 0')
    end

    def debit
      where('debit > 0')
    end
  end
  has_many :purchase_payments, dependent: :nullify
  has_many :incoming_payments, dependent: :nullify
  has_many :payslips, dependent: :nullify
  has_many :payslip_payments, dependent: :nullify
  has_many :purchases, dependent: :nullify
  has_many :regularizations, dependent: :nullify
  has_many :sales, dependent: :nullify
  has_one :financial_year_as_last, foreign_key: :last_journal_entry_id, class_name: 'FinancialYear', dependent: :nullify
  has_many :bank_statements, through: :useful_items

  def resource_label
    @resource_label ||= [resource&.class&.model_name&.human, resource&.number].compact.join(' ')
  end

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :absolute_credit, :absolute_debit, :balance, :credit, :debit, :real_balance, :real_credit, :real_debit, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :absolute_currency, :currency, :journal, :real_currency, presence: true
  validates :continuous_number, uniqueness: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, :reference_number, :resource_prism, :resource_type, length: { maximum: 500 }, allow_blank: true
  validates :number, :state, presence: true, length: { maximum: 500 }
  validates :printed_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :real_currency_rate, presence: true, numericality: { greater_than: -1_000_000_000, less_than: 1_000_000_000 }
  validates :validated_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :absolute_currency, :currency, :real_currency, length: { allow_nil: true, maximum: 3 }
  validates :state, length: { allow_nil: true, maximum: 30 }
  validates :real_currency, presence: true
  validates :number, format: { with: /\A[\dA-Z]+\z/ }
  validates :real_currency_rate, numericality: { greater_than: 0 }
  validates :number, uniqueness: { scope: %i[journal_id financial_year_id] }
  validates :printed_on, financial_year_writeable: true, allow_blank: true
  validates :name, presence: true

  accepts_nested_attributes_for :items, reject_if: :all_blank, allow_destroy: true

  scope :between, lambda { |started_on, stopped_on|
    where(printed_on: started_on..stopped_on)
  }

  state_machine :state, initial: :draft do
    state :draft
    state :confirmed
    state :closed
    before_transition to: :confirmed do |model, _transition|
      model.validated_at = Time.zone.now
    end
    event :confirm do
      transition draft: :confirmed, if: :balanced?
    end
    event :close do
      transition draft: :closed, if: :balanced?
      transition confirmed: :closed, if: :balanced?
    end
    # event :reopen do
    #   transition :closed => :confirmed
    # end
  end

  class << self
    # Build an SQL condition based on options which should contains acceptable states
    # @deprecated
    def state_condition(states = {}, table_name = nil)
      if states.nil?
        ActiveSupport::Deprecation.warn('Providing nil to `state_condition` is deprecated and will not work in the future, give an empty array instead')

        states = []
      end

      if !states.is_a?(Array)
        if states.respond_to?(:keys)
          ActiveSupport::Deprecation.warn('Providing something else than an array of states to `state_condition` is deprecated.')
          states = states.keys
        else
          raise StandardError.new("Unable to find any state in the variable provided (#{states})")
        end
      end

      condition_builder.state_condition(states, table_name: table_name || self.table_name)
    end

    # Build an SQL condition based on options which should contains acceptable states
    # @deprecated
    def journal_condition(journals = {}, table_name = nil)
      if journals.nil?
        ActiveSupport::Deprecation.warn('Providing nil to `state_condition` is deprecated and will not work in the future, give an empty array instead')

        journals = []
      end

      if !journals.is_a?(Array)
        if journals.respond_to?(:keys)
          ActiveSupport::Deprecation.warn('Providing something else than an array of states to `state_condition` is deprecated.')
          journals = journals.select { |_k, v| v == '1' }.keys
        else
          raise StandardError.new("Unable to find any state in the variable provided (#{journals})")
        end
      end

      condition_builder.journal_condition(journals, table_name: table_name || self.table_name)
    end

    # Build a condition for filter journal entries on period
    # @deprecated
    def period_condition(period, started_on, stopped_on, table_name = nil)
      condition_builder.period_condition(period, started_on: started_on, stopped_on: stopped_on, table_name: table_name || self.table_name)
    end

    # Returns states names
    def states
      state_machine.states.collect(&:name)
    end

    private

      # @deprecated
      def condition_builder
        ActiveSupport::Deprecation.warn 'JournalEntry condition methods are deprecated, use Accountancy::ConditionBuilder::* instead'
        Accountancy::ConditionBuilder::JournalEntryConditionBuilder.new(connection: connection)
      end
  end

  # return the letter if any on items
  def letter
    items.distinct.pluck(:letter).compact.first
  end

  # return the isacompta_letter if any on items
  def isacompta_letter
    items.distinct.pluck(:isacompta_letter).compact.first
  end

  def complete_letter
    l = items.pluck(:letter).compact.uniq.first
    if l && l.include?('*')
      nil
    elsif l
      l
    end
  end

  def lettered_at
    items.pluck(:lettered_at).compact.uniq.first
  end

  # return the date of the first payment (incomming or outgoing)
  def first_payment
    if purchase_payments.any?
      purchase_payments.reorder(:paid_at).first
    elsif incoming_payments.any?
      incoming_payments.reorder(:paid_at).first
    end
  end

  before_validation on: :create do
    self.state ||= :draft
  end

  before_validation do
    self.resource_type = resource.class.base_class.name if resource
    self.real_currency = journal.currency if journal
    if printed_on?
      self.financial_year = expected_financial_year
      self.currency = financial_year.currency if financial_year
    end
    if real_currency && financial_year
      self.real_currency_rate = 1 if real_currency == financial_year.currency
    else
      self.real_currency_rate = 1
    end

    items.to_a.each(&:compute)

    self.real_debit = items.to_a.reduce(0) { |sum, item| sum + (item.marked_for_destruction? ? 0 : item.real_debit || 0) }
    self.real_credit = items.to_a.reduce(0) { |sum, item| sum + (item.marked_for_destruction? ? 0 : item.real_credit || 0) }
    self.real_balance = real_debit - real_credit

    self.debit = items.to_a.reduce(0) { |sum, item| sum + (item.marked_for_destruction? ? 0 : item.debit || 0) }
    self.credit = items.to_a.reduce(0) { |sum, item| sum + (item.marked_for_destruction? ? 0 : item.credit || 0) }

    self.balance = debit - credit

    if real_balance.zero? && !balance.zero?
      magnitude = 10 ** Onoma::Currency.find(currency).precision
      error_sum = balance * magnitude
      column = error_sum > 0 ? :credit : :debit

      error_sum = error_sum.abs

      even_items = items.reject { |item| item.send(column).zero? }
      proratas = even_items.map { |item| [item, item.send(column) / send(column)] }.to_h
      proratas.reduce(error_sum) do |left, (item, prorata)|
        error_to_update = [(error_sum * prorata).ceil / magnitude.to_f, left].min
        item.send(:"#{column}=", item.send(column) + error_to_update)

        left - error_to_update * magnitude
      end

      self.debit = items.to_a.reduce(0) { |sum, item| sum + (item.debit || 0) }
      self.credit = items.to_a.reduce(0) { |sum, item| sum + (item.credit || 0) }

      self.balance = debit - credit
    end

    self.absolute_currency = Preference[:currency]
    if absolute_currency == currency
      self.absolute_debit = debit
      self.absolute_credit = credit
    elsif absolute_currency == real_currency
      self.absolute_debit = real_debit
      self.absolute_credit = real_credit
    else
      # FIXME: We need to do something better when currencies don't match
      if currency.present? && (absolute_currency.present? || real_currency.present?)
        raise IncompatibleCurrencies.new("You cannot create an entry where the absolute currency (#{absolute_currency.inspect}) is not the real (#{real_currency.inspect}) or current one (#{currency.inspect})")
      end
    end
    if number.present?
      number.upcase!
    elsif journal
      self.number ||= journal.next_number
    end

    self.currency = absolute_currency if financial_year.blank?

    self.name = items.first.name if self.name.nil? && items.any?
  end

  validate(on: :update) do
    old = self.class.find(id)
    errors.add(:number, :entry_has_been_already_validated) if old.closed?
  end

  validate do
    # TODO: Validates number has journal's code as prefix
    if printed_on
      if journal
        errors.add(:printed_on, :closed_journal, journal: journal.name, closed_on: ::I18n.localize(journal.closed_on)) if printed_on < journal.closed_on
      end
      unless financial_year
        errors.add(:printed_on, :out_of_existing_financial_year)
      end
    end
    if in_opened_financial_year_exchange? && !importing_from_exchange
      errors.add(:printed_on, :frozen_by_financial_year_exchange)
    end
    errors.add(:items, :empty) unless items.any?
    errors.add(:balance, :unbalanced) unless balance.zero?
    errors.add(:real_balance, :unbalanced) unless real_balance.zero?
  end

  after_save do
    # Item caching process also handled via a trigger in DB.
    # See migration AddEntryDataSynchro if needed.
    JournalEntryItem.where(entry_id: id).update_all(
      state: self.state,
      journal_id: journal_id,
      financial_year_id: financial_year_id,
      printed_on: printed_on,
      entry_number: self.number,
      real_currency: real_currency,
      real_currency_rate: real_currency_rate
    )
    regularizations.each(&:save)

    compliance = { vendor: :fec, name: :journal_entries, data: { errors: FEC::Check::JournalEntry.validate(self) } }
    self.update_column(:compliance, compliance)
  end

  before_destroy do
    items.each(&:clear_bank_statement_reconciliation)
  end

  protect on: :update do
    !importing_from_exchange && (printed_on <= journal.closed_on || old_record.closed? || (old_record.confirmed? && (changes_to_save.keys - %w[state updated_at]).any?))
  end

  protect on: :destroy do
    !importing_from_exchange && (printed_on <= journal.closed_on || old_record.closed? || old_record.confirmed?)
  end

  def editable?
    state_name == :draft
  end

  def need_currency_change?
    return nil unless journal

    year_currency = if financial_year
                      financial_year.currency
                    elsif printed_on? && (year = FinancialYear.on(printed_on))
                      year.currency
                    else
                      Preference[:currency]
                    end
    year_currency != journal.currency
  end

  def expected_financial_year
    raise 'Missing printed_on' unless printed_on

    FinancialYear.on(printed_on)
  end

  def entities_bank_statement_number
    items.where.not(bank_statement_letter: nil).first&.bank_statement_letter
  end

  def self.state_label(state)
    tc('states.' + state.to_s)
  end

  # Prints human name of current state
  def state_label
    self.class.state_label(self.state)
  end

  def bank_statement_number
    bank_statements.first.number if bank_statements.first
  end

  # return the label of the main client_or_supplier_account of an entry
  # in order to show which client or supplier is involved in the entry items
  def main_client_or_supplier_account
    third_accounts = Account.where(id: items.pluck(:account_id)).thirds.reorder(:number)
    if third_accounts.any?
      third_accounts.first.label
    else
      nil
    end
  end

  # FIXME: Nothing to do here. What's the meaning?
  def entity_country_code
    resource && resource.respond_to?(:third) &&
      resource.third && resource.third.country
  end

  # FIXME: Nothing to do here. What's the meaning?
  def entity_country
    entity_country_code && resource.third.country.l
  end

  # determines if the entry is balanced or not.
  def balanced?
    balance.zero? # and self.items.count > 0
  end

  # this method computes the debit and the credit of the entry.
  def refresh
    reload
    save!
  end

  # Destroy or cancel journal depending on its current state
  def remove
    reverse_entry = nil
    if draft?
      destroy
    else
      reverse_entry = cancel
    end
    reverse_entry
  end

  # Add a entry which cancel the entry
  # Create counter-entry_items
  def cancel
    return nil unless useful_items.any?

    ApplicationRecord.transaction do
      reconcilable_accounts = []
      list = []
      useful_items.each do |item|
        list << JournalEntryItem.new_for(
          tc(:entry_cancel, number: self.number, name: item.name),
          item.account, (item.debit - item.credit).abs, credit: (item.debit > 0)
        )
        if item.account.reconcilable? && !reconcilable_accounts.include?(item.account)
          reconcilable_accounts << item.account
        end
      end
      entry = self.class.create!(
        journal: journal,
        resource: resource,
        real_currency: real_currency,
        real_currency_rate: real_currency_rate,
        printed_on: printed_on,
        items: list
      )
      # Mark accounts
      reconcilable_accounts.each do |account|
        account.mark_entries(self, entry)
      end
      entry
    end
  end

  # Adds an entry_item with the minimum informations. It computes debit and credit with the "amount".
  # If the amount is negative, the amount is put in the other column (debit or credit). Example:
  #   entry.add_debit("blabla", account, -65) # will put +65 in +credit+ column
  def add_debit(name, account, amount, options = {})
    add!(name, account, amount, options)
  end

  def add_credit(name, account, amount, options = {})
    add!(name, account, amount, options.merge(credit: true))
  end

  # Flag the entry updatable and destroyable, used during financial year exchange import
  def mark_for_exchange_import!
    self.importing_from_exchange = true
  end

  def currently_exchanged?
    financial_year_exchange_id.present?
  end

  # --- FEC methods start ---

  def fec_base_errors
    base_fec_errors = FEC::Check::JournalEntry.base_errors_name
    compliance_errors.select { |err| base_fec_errors.include?(err) }
  end

  def fec_date_errors
    date_fec_errors = FEC::Check::JournalEntry.date_errors_name
    compliance_errors.select { |err| date_fec_errors.include?(err) }
  end

  def has_fec_base_error
    fec_base_errors.any?
  end

  def has_fec_date_error
    fec_date_errors.any?
  end

  def has_no_fec_data
    compliance_data.empty?
  end

  def duplicated_number_accounts
    non_uniq_name_account = Account.with_non_uniq_name
    duplicated_number_accounts = []
    items.map(&:account).uniq.each do |jei|
      next if duplicated_number_accounts.include?(jei.number)
      next if non_uniq_name_account.exclude?(jei.name)

      duplicated_number_accounts << jei.number
    end
    duplicated_number_accounts
  end

  def invalid_accounts_number_count
    items.joins(:account).where("LENGTH(accounts.number) < 3").count
  end

  # --- FEC methods end ---

  class << self
    def fec_compliance_preference
      pref = Preference.global.find_by(name: :check_fec_compliance)
      return false if pref.nil?

      pref.boolean_value
    end
  end

  private

    attr_accessor :importing_from_exchange

    def add!(name, account, amount, options = {})
      items.create!(JournalEntryItem.attributes_for(name, account, amount, options))
    end

    def in_opened_financial_year_exchange?
      financial_year.present? && financial_year.exchanges.opened.at(printed_on).exists?
    end
end
