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
# == Table: entities
#
#  active                       :boolean          default(TRUE), not null
#  activity_code                :string
#  authorized_payments_count    :integer
#  bank_account_holder_name     :string
#  bank_identifier_code         :string
#  born_at                      :datetime
#  client                       :boolean          default(FALSE), not null
#  client_account_id            :integer
#  client_payment_delay       :string
#  client_payment_mode_id     :integer
#  codes                        :jsonb
#  country                      :string
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  currency                     :string           not null
#  custom_fields                :jsonb
#  dead_at                      :datetime
#  deliveries_conditions        :string
#  description                  :text
#  employee                     :boolean          default(FALSE), not null
#  employee_account_id          :integer
#  first_financial_year_ends_on :date
#  first_met_at                 :datetime
#  first_name                   :string
#  full_name                    :string           not null
#  iban                         :string
#  id                           :integer          not null, primary key
#  language                     :string           not null
#  last_name                    :string           not null
#  legal_position_code          :string
#  lock_version                 :integer          default(0), not null
#  locked                       :boolean          default(FALSE), not null
#  meeting_origin               :string
#  nature                       :string           not null
#  number                       :string
#  of_company                   :boolean          default(FALSE), not null
#  picture_content_type         :string
#  picture_file_name            :string
#  picture_file_size            :integer
#  picture_updated_at           :datetime
#  proposer_id                  :integer
#  prospect                     :boolean          default(FALSE), not null
#  provider                     :jsonb
#  reminder_submissive          :boolean          default(FALSE), not null
#  responsible_id               :integer
#  siret_number                 :string
#  supplier                     :boolean          default(FALSE), not null
#  supplier_account_id          :integer
#  supplier_payment_delay       :string
#  supplier_payment_mode_id     :integer
#  title                        :string
#  transporter                  :boolean          default(FALSE), not null
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  vat_number                   :string
#  vat_subjected                :boolean          default(TRUE), not null
#

require 'digest/sha2'

class Entity < ApplicationRecord
  include Attachable
  include Autocastable
  include Commentable
  include Versionable
  include Customizable
  include Providable
  attr_accessor :password_confirmation, :old_password
  refers_to :currency
  refers_to :language
  refers_to :country
  enumerize :nature, in: %i[organization contact], default: :organization, predicates: true
  enumerize :supplier_payment_delay, in: ['1 week', '30 days', '30 days, end of month', '60 days', '60 days, end of month']
  enumerize :client_payment_delay, in: ['1 week', '30 days', '30 days, end of month', '60 days', '60 days, end of month']
  # TODO: it should be rewritten when refers_to_lexicon is available
  enumerize :legal_position_code, in: MasterLegalPosition.pluck(:code)
  versionize exclude: [:full_name]
  belongs_to :client_account, class_name: 'Account'
  belongs_to :employee_account, class_name: 'Account'
  # belongs_to :payment_mode, class_name: "IncomingPaymentMode"
  belongs_to :proposer, class_name: 'Entity'
  belongs_to :responsible, class_name: 'User'
  belongs_to :supplier_account, class_name: 'Account'
  belongs_to :supplier_payment_mode, class_name: 'OutgoingPaymentMode'
  belongs_to :client_payment_mode, class_name: 'IncomingPaymentMode'
  has_many :clients, class_name: 'Entity', foreign_key: :responsible_id, dependent: :nullify
  with_options class_name: 'EntityAddress', inverse_of: :entity, dependent: :destroy do
    has_many :all_addresses
    has_many :addresses, -> { actives }
    has_many :mails,     -> { actives.mails    }
    has_many :emails,    -> { actives.emails   }
    has_many :phones,    -> { actives.phones   }
    has_many :mobiles,   -> { actives.mobiles  }
    has_many :faxes,     -> { actives.faxes    }
    has_many :websites,  -> { actives.websites }
    has_many :auto_updateable_addresses, -> { actives.where(mail_auto_update: true) }
  end
  has_many :contracts, foreign_key: :supplier_id, dependent: :restrict_with_exception
  has_many :direct_links, class_name: 'EntityLink', foreign_key: :entity_id, dependent: :destroy
  has_many :gaps, dependent: :restrict_with_error
  has_many :idea_diagnostics, foreign_key: :auditor_id, dependent: :nullify
  has_many :issues, as: :target, dependent: :destroy
  has_many :godchildren, class_name: 'Entity', foreign_key: 'proposer_id'
  has_many :incoming_payments, foreign_key: :payer_id, inverse_of: :payer
  has_many :outcoming_payments, class_name: 'OutgoingPayment', foreign_key: :payee_id, inverse_of: :payee
  has_many :indirect_links, class_name: 'EntityLink', foreign_key: :linked_id, dependent: :destroy
  has_many :purchase_payments, foreign_key: :payee_id
  has_many :ownerships, class_name: 'ProductOwnership', foreign_key: :owner_id
  has_many :participations, class_name: 'EventParticipation', foreign_key: :participant_id, dependent: :destroy
  has_many :events, through: :participations
  has_many :purchase_invoices, class_name: 'PurchaseInvoice', foreign_key: :supplier_id
  has_many :purchase_orders, class_name: 'PurchaseOrder', foreign_key: :supplier_id
  has_many :purchases, foreign_key: :supplier_id, dependent: :restrict_with_exception
  has_many :purchase_items, through: :purchases, source: :items
  has_many :parcels, foreign_key: :transporter_id
  has_many :receptions, foreign_key: :sender_id
  has_many :shipments, foreign_key: :recipient_id
  has_many :sales_invoices, -> { where(state: 'invoice').order(created_at: :desc) },
           class_name: 'Sale', foreign_key: :client_id
  has_many :sales, -> { order(created_at: :desc) }, foreign_key: :client_id, dependent: :restrict_with_exception
  has_many :sale_opportunities, -> { order(created_at: :desc) }, foreign_key: :third_id, dependent: :destroy
  has_many :managed_sales, -> { order(created_at: :desc) }, foreign_key: :responsible_id, class_name: 'Sale'
  has_many :sale_items, through: :sales, source: :items
  has_many :subscriptions, foreign_key: :subscriber_id, dependent: :restrict_with_error
  has_many :tasks
  has_many :trackings, foreign_key: :producer_id
  has_many :deliveries, foreign_key: :transporter_id, dependent: :restrict_with_error
  has_many :transporter_sales, -> { order(created_at: :desc) }, foreign_key: :transporter_id, class_name: 'Sale'
  has_many :waiting_deliveries, -> { where(state: 'ready_to_send') }, class_name: 'Parcel', foreign_key: :transporter_id
  has_many :booked_journals, class_name: 'Journal', foreign_key: :accountant_id
  has_many :financial_years, class_name: 'FinancialYear', foreign_key: :accountant_id
  has_many :purchase_affairs, -> { order(created_at: :desc) }, foreign_key: :third_id, dependent: :destroy
  has_many :client_journal_entry_items, through: :client_account, source: :journal_entry_items
  has_many :supplier_journal_entry_items, through: :supplier_account, source: :journal_entry_items

  with_options class_name: 'EntityAddress' do
    has_one :default_mail_address, -> { where(by_default: true, canal: 'mail') }
    has_one :default_email_address, -> { where(by_default: true, canal: 'email') }
    has_one :default_phone_address, -> { where(by_default: true, canal: 'phone') }
    has_one :default_mobile_address, -> { where(by_default: true, canal: 'mobile') }
    has_one :default_fax_address, -> { where(by_default: true, canal: 'fax') }
    has_one :default_website_address, -> { where(by_default: true, canal: 'website') }
  end
  has_one :economic_situation, foreign_key: :id
  has_one :cash, class_name: 'Cash', foreign_key: :owner_id
  has_one :worker, foreign_key: :person_id
  has_one :user, foreign_key: :person_id
  has_many :worker_contracts, class_name: 'WorkerContract', inverse_of: :entity, foreign_key: :entity_id, dependent: :destroy
  has_picture

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :client, :employee, :locked, :of_company, :prospect, :reminder_submissive, :supplier, :transporter, :vat_subjected, inclusion: { in: [true, false] }
  validates :activity_code, :bank_account_holder_name, :bank_identifier_code, :deliveries_conditions, :first_name, :iban, :meeting_origin, :number, :picture_content_type, :picture_file_name, :siret_number, :title, :vat_number, length: { maximum: 500 }, allow_blank: true
  validates :born_at, :dead_at, :first_met_at, :picture_updated_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :currency, :language, :nature, presence: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :first_financial_year_ends_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years }, type: :date }, allow_blank: true
  validates :full_name, :last_name, presence: true, length: { maximum: 500 }
  validates :picture_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  # ]VALIDATORS]
  validates :country, length: { allow_nil: true, maximum: 2 }
  validates :language, length: { allow_nil: true, maximum: 3 }
  validates :vat_number, length: { allow_nil: true, maximum: 20 }
  validates :activity_code, length: { allow_nil: true, maximum: 30 }
  validates :deliveries_conditions, :number, length: { allow_nil: true, maximum: 60 }
  validates :iban, iban: true, allow_blank: true
  validates :siret_number, siret_format: { if: :in_france? }, allow_blank: true, length: { allow_nil: true, maximum: 14 }
  validates_attachment_content_type :picture, content_type: /image/
  validates_delay_format_of :supplier_payment_delay
  validates_with SEPA::BICValidator, field_name: :bank_identifier_code

  alias_attribute :name, :full_name

  scope :normal, -> { where(of_company: false) }
  scope :necessary_transporters, -> { where("transporter OR id IN (SELECT transporter_id FROM #{Parcel.table_name} WHERE state != 'sent' OR delivery_id IS NULL)").order(:last_name, :first_name) }
  scope :suppliers,    -> { where(supplier: true) }
  scope :transporters, -> { where(transporter: true) }
  scope :clients,      -> { where(client: true) }
  scope :employees,    -> { where(employee: true) }
  scope :company,      -> { where(of_company: true) }
  scope :related_to, lambda { |entity|
    where("id IN (SELECT linked_id FROM #{EntityLink.table_name} WHERE entity_id = ?) OR id IN (SELECT entity_id FROM #{EntityLink.table_name} WHERE linked_id = ?)", entity.id, entity.id)
  }
  scope :users, -> { where(id: User.select(:person_id)) }
  scope :responsibles,  -> { contacts }
  scope :contacts,      -> { where(nature: 'contact') }
  scope :organizations, -> { where(nature: 'organization') }
  scope :with_address, ->(canal, coordinate) {
    where(id: EntityAddress.where(canal: canal, coordinate: coordinate).select(:entity_id))
  }
  scope :with_email, ->(email) { with_address(:email, email) }

  acts_as_numbered :number, force: false, readonly: false
  accepts_nested_attributes_for :mails,    reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :emails,   reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :phones,   reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :mobiles,  reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :faxes,    reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :websites, reject_if: :all_blank, allow_destroy: true

  selects_among_all :of_company

  before_validation do
    self.first_name = first_name.to_s.strip
    self.first_name = nil if organization?
    self.last_name = last_name.to_s.strip
    self.number = unique_predictable_number if number.empty?
    # FIXME: I18nize full name computation
    self.full_name = (title.to_s + ' ' + first_name.to_s + ' ' + last_name.to_s).strip
    # unless self.nature.nil?
    # self.full_name = (self.nature.title.to_s + ' ' + self.full_name).strip unless self.nature.in_name? # or self.nature.abbreviation == "-")
    # end
    full_name.strip!
    # self.name = self.name.to_s.strip.downcase.gsub(/[^a-z0-9\.\_]/,'')
    self.siret_number = siret_number.strip if siret_number
    self.language = Preference[:language] if language.blank?
    self.currency = Preference[:currency] if currency.blank?
    self.country = Preference[:country] if country.blank?
    self.iban = iban.to_s.upper.gsub(/[^A-Z0-9]/, '')
    self.bank_identifier_code = bank_identifier_code.to_s.upper.gsub(/[^A-Z0-9]/, '').presence
    self.bank_account_holder_name = full_name if bank_account_holder_name.blank?
    self.bank_account_holder_name = I18n.transliterate(bank_account_holder_name) unless bank_account_holder_name.nil?
    self.supplier_payment_delay = '30 days' if supplier_payment_delay.blank?
  end

  before_save do
    self.born_at ||= Time.new(2008, 1, 1) if of_company
  end

  after_save do
    auto_updateable_addresses.find_each do |a|
      a.mail_line_1 = full_name
      a.save
    end
    # create account before bookkeep on sale and purchase
    self.account(:client) if client
    self.account(:supplier) if supplier
    self.account(:employee) if employee
  end

  protect(on: :destroy) do
    of_company? || sales_invoices.any? || outcoming_payments.any? || incoming_payments.any? || participations.any? || sales.any? || parcels.any? || purchases.any? || receptions.any? || shipments.any? || financial_year_with_opened_exchange?
  end

  class << self
    prepend IdHumanizable

    def exportable_columns
      content_columns.delete_if do |c|
        %i[active lock_version deliveries_conditions].include?(c.name.to_sym)
      end
    end

    # Returns a default company entity.
    # TODO: Externalizes these informations to prevent export/overwriting errors
    def of_company
      company = find_by(of_company: true)
      unless company
        user = User.order(:id).first
        company = Entity.create!(
          nature: :organization,
          last_name: user ? user.last_name : 'COMPANY',
          of_company: true
        )
      end
      company
    end
  end

  def legal_position
    MasterLegalPosition.find_by(code: legal_position_code)
  end

  def of_capital?
    return false unless legal_position

    legal_position.nature == "capital"
  end

  def of_person?
    return false unless legal_position

    legal_position.nature == "person"
  end

  def of_individual?
    return false unless legal_position

    legal_position.nature == "individual"
  end

  def entity_payment_mode_name
    supplier_payment_mode&.name
  end

  # Convert a contact into organization or inverse
  def toggle!
    if contact? && first_name.present?
      self.last_name = first_name + ' ' + last_name
    end
    self.nature = contact? ? :organization : :contact
    save!
  end

  def unbalanced?
    EconomicSituation.unbalanced.pluck(:id).include? id
  end

  def in_france?
    country == 'fr'
  end

  def client_accounting_balance
    return 0.0 unless client?

    economic_situation[:client_accounting_balance]
  end

  def supplier_accounting_balance
    return 0.0 unless supplier?

    economic_situation[:supplier_accounting_balance]
  end

  # Returns an entity scope for.all other entities
  def others
    self.class.where('id != ?', (id || 0))
  end

  def label
    number.to_s + '. ' + full_name.to_s
  end

  def siren_number
    siret_number[0..8] if siret_number
  end

  def siren
    ActiveSupport::Deprecation.warn('Entity#siren is deprecated. Please use Entity#siren_number instead. This method will be removed in Ekylibre 3.')
    siren_number
  end

  def last_incoming_payment
    incoming_payments.last_updateds.first
  end

  def balance
    economic_situation[:trade_balance]
  end

  def has_another_tracking?(serial, product_id)
    trackings.where('serial=? AND product_id!=? ', serial, product_id).count > 0
  end

  # This method creates automatically an account for the entity for its usage (client, supplier...)
  def account(nature)
    natures = Account::CENTRALIZING_NATURES
    conversions = { payer: :client, payee: :supplier }
    nature = nature.to_sym
    nature = conversions[nature] || nature
    unless natures.include?(nature)
      raise ArgumentError.new("Unknown nature #{nature.inspect} (#{natures.to_sentence} are accepted)")
    end

    valid_account = send("#{nature}_account")
    if valid_account.nil?
      prefix = Account.centalizing_account_prefix_for(nature)

      account_nomen = nature.to_s.pluralize
      account_nomen = :staff_due_remunerations if nature == :employee

      if account_nomen == 'clients' || account_nomen == 'suppliers'
        if Preference[:use_entity_codes_for_account_numbers]
          number = prefix.to_s + self.number.to_s
          auxiliary_number = self.number.to_s
          unless (valid_account = Account.find_by(number: number))
            valid_account = Account.create(nature: 'auxiliary', auxiliary_number: auxiliary_number, name: full_name, centralizing_account_name: account_nomen, reconcilable: true)
          end
        else
          suffix = '1'
          suffix = suffix.upper_ascii[0..5].rjust(6, '0')
          account = 1
          until account.nil?
            account = Account.find_by('number LIKE ?', prefix.to_s + suffix.to_s)
            suffix.succ! unless account.nil?
          end
          valid_account = Account.create(nature: 'auxiliary', auxiliary_number: suffix.to_s, name: full_name, centralizing_account_name: account_nomen, reconcilable: true)
        end
      else
        _employees_account = Account.find_or_import_from_nomenclature(account_nomen)

        valid_account = Account.find_or_create_by_number(Account.generate_employee_account_number_for(id), name: full_name)
      end
      reload.update_column("#{nature}_account_id", valid_account.id)
    end
    valid_account
  end

  def warning
    count = observations.where(importance: 'important').count
    # count += self.balance<0 ? 1 : 0
  end

  def add_event(usage, operator, at = Time.zone.now)
    if operator && item = Onoma::EventNature[usage]
      Event.create!(name: item.human_name, started_at: at, duration: item.default_duration.to_i, participations_attributes: { '0' => { participant_id: id, state: 'informative' }, '1' => { participant_id: operator.id, state: 'accepted' } })
    end
  end

  def default_mail_coordinate
    default_mail_address ? default_mail_address.coordinate : nil
  end

  def default_mail_address_id
    default_mail_address ? default_mail_address.id : nil
  end

  def link_to!(entity, options = {})
    nature = options[:as] || :undefined
    unless direct_links.actives.where(nature: nature.to_s, linked_id: entity.id).any?
      direct_links.create!(nature: nature.to_s, linked_id: entity.id)
    end
  end

  def maximal_reduction_percentage(computed_at = Time.zone.today)
    Subscription
      .joins("JOIN #{SubscriptionNature.table_name} AS sn ON (#{Subscription.table_name}.nature_id = sn.id) LEFT JOIN #{EntityLink.table_name} AS el ON (el.nature = sn.entity_link_nature AND #{Subscription.table_name}.subscriber_id IN (entity_id, linked_id))")
      .where("? IN (#{Subscription.table_name}.subscriber_id, entity_id, linked_id) AND ? BETWEEN #{Subscription.table_name}.started_at AND #{Subscription.table_name}.stopped_at AND COALESCE(#{Subscription.table_name}.sale_id, 0) NOT IN (SELECT id FROM #{Sale.table_name} WHERE state='estimate')", id, computed_at)
      .maximum(:reduction_percentage).to_f || 0.0
  end

  def last_subscription(nature)
    subscriptions.where(nature: nature).order(stopped_on: :desc).first
  end

  def picture_path(style = :original)
    picture.path(style)
  end

  def name_with_postal_code_and_city
    desc = (number.nil? ? '' : number) + '. ' + full_name
    c = default_mail_address
    desc += ' (' + c.mail_line_6.to_s + ')' unless c.nil?
    desc
  end

  # Merge given entity into record. Alls related records of given entity will point on
  # self. Given entity is destroyed at the end, self remains.
  def merge_with(other, options = {})
    raise StandardError.new('Company entity is not mergeable') if other.of_company?

    author = options[:author]
    ApplicationRecord.transaction do
      # EntityAddress
      threads = EntityAddress.unscoped.where(entity_id: id).distinct.pluck(:thread).delete_if(&:blank?)
      other_threads = EntityAddress.unscoped.where(entity_id: other.id).distinct.pluck(:thread).delete_if(&:blank?)
      other_threads.each do |thread|
        thread.succ! while threads.include?(thread)
        threads << thread
        EntityAddress.unscoped.where(entity_id: other.id).update_all(thread: thread, by_default: false)
      end

      # Relations with DB approach to prevent missing reflection
      connection = self.class.connection
      base_class = self.class.base_class
      base_model = base_class.name.underscore.to_sym
      models_set = ([base_class] + base_class.descendants)
      models_group = '(' + models_set.map do |model|
        "'#{model.name}'"
      end.join(', ') + ')'
      Ekylibre::Schema.tables.each do |table, columns|
        columns.each do |_name, column|
          next unless column.references

          if column.references.is_a?(String) # Polymorphic
            connection.execute("UPDATE #{table} SET #{column.name}=#{id} WHERE #{column.name}=#{other.id} AND #{column.references} IN #{models_group}")
          elsif column.references == base_model # Straight
            connection.execute("UPDATE #{table} SET #{column.name}=#{id} WHERE #{column.name}=#{other.id}")
          end
        end
      end

      # Update attributes
      %i[currency country last_name first_name activity_code description born_at dead_at deliveries_conditions first_met_at meeting_origin proposer siret_number supplier_account client_account vat_number language authorized_payments_count].each do |attr|
        send("#{attr}=", other.send(attr)) if send(attr).blank?
      end
      if other.picture.file? && !picture.file?
        self.picture = File.open(other.picture.path(:original))
      end

      # Update custom fields
      self.custom_fields ||= {}
      other.custom_fields ||= {}
      Entity.custom_fields.each do |custom_field|
        attr = custom_field.column_name
        if self.custom_fields[attr].blank? && other.custom_fields[attr].present?
          self.custom_fields[attr] = other.custom_fields[attr]
        end
      end

      save!

      # Add summary observation of the merge
      if author
        content = :merged_entity.tl(other: other.id)
        other.attributes.sort.each do |attr, value|
          next unless value.present?

          if ["supplier_payment_delay", "nature"].include?(attr)
            value = "enumerize.entity.#{attr}.#{value}".t
          elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
            value = value ? :y.tl : :n.tl
          else
            value = value.to_s
          end

          content << "  - #{Entity.human_attribute_name(attr)} : #{value}\n" if value.present?
        end
        Entity.custom_fields.each do |custom_field|
          value = other.custom_fields[custom_field.column_name].to_s
          content << "  - #{custom_field.name} : #{value}\n" if value.present?
        end

        observations.create!(content: content, importance: 'normal', author: author)
      end

      # Remove doublon
      other.destroy
    end
  end

  def born_on
    born_at.to_date
  end

  def financial_year_with_opened_exchange?
    return false unless persisted?

    financial_years.any?(&:opened_exchange?)
  end

  def self.best_clients(limit = -1)
    clients.sort_by { |client| -client.sales.count }[0...limit]
  end

  def self.importable_columns
    columns = []
    columns << [tc('import.dont_use'), 'special-dont_use']
    columns << [tc('import.generate_string_custom_field'), 'special-generate_string_custom_field']
    # columns << [tc("import.generate_choice_custom_field"), "special-generate_choice_custom_field"]
    cols = Entity.content_columns.delete_if { |c| %i[active full_name lock_version updated_at created_at].include?(c.name.to_sym) || c.type == :boolean }.collect(&:name)
    columns += cols.collect { |c| [Entity.model_name.human + '/' + Entity.human_attribute_name(c), 'entity-' + c] }.sort
    cols = EntityAddress.content_columns.collect(&:name).delete_if { |c| %i[number started_at stopped_at deleted address by_default closed_at lock_version active updated_at created_at].include?(c.to_sym) } + %w[item_6_city item_6_code]
    columns += cols.collect { |c| [EntityAddress.model_name.human + '/' + EntityAddress.human_attribute_name(c), 'address-' + c] }.sort
    columns += %w[name abbreviation].collect { |c| [EntityNature.model_name.human + '/' + EntityNature.human_attribute_name(c), 'entity_nature-' + c] }.sort
    # columns += ["name"].collect{|c| [Catalog.model_name.human+"/"+Catalog.human_attribute_name(c), "product_price_listing-"+c]}.sort
    columns += CustomField.where("nature in ('string')").collect { |c| [CustomField.model_name.human + '/' + c.name, 'custom_field-id' + c.id.to_s] }.sort
    columns
  end
end
