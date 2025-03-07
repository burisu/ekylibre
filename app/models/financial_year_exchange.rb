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
# == Table: financial_year_exchanges
#
#  analytical_codes                  :boolean          default(FALSE), not null
#  closed_at                         :datetime
#  created_at                        :datetime         not null
#  creator_id                        :integer
#  financial_year_id                 :integer          not null
#  format                            :string           default("ekyagri"), not null
#  id                                :integer          not null, primary key
#  import_file_content_type          :string
#  import_file_file_name             :string
#  import_file_file_size             :integer
#  import_file_updated_at            :datetime
#  lock_version                      :integer          default(0), not null
#  public_token                      :string
#  public_token_expired_at           :datetime
#  started_on                        :date             not null
#  stopped_on                        :date             not null
#  transmit_isacompta_analytic_codes :boolean          default(FALSE)
#  updated_at                        :datetime         not null
#  updater_id                        :integer
#

class FinancialYearExchange < ApplicationRecord
  belongs_to :financial_year

  has_many :journal_entries, dependent: :nullify
  has_many :journals

  has_one :accountant, through: :financial_year
  has_attached_file :import_file, path: ':tenant/:class/:id/:style.:extension'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :closed_at, :import_file_updated_at, :public_token_expired_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :exported_journal_ids, :import_file_content_type, :import_file_file_name, length: { maximum: 500 }, allow_blank: true
  validates :financial_year, :format, presence: true
  validates :import_file_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :public_token, uniqueness: true, length: { maximum: 500 }, allow_blank: true
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(financial_year_exchange) { financial_year_exchange.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :transmit_isacompta_analytic_codes, inclusion: { in: [true, false] }, allow_blank: true
  # ]VALIDATORS]
  validates :stopped_on, presence: true, timeliness: { on_or_before: ->(exchange) { exchange.financial_year_stopped_on || (Time.zone.today + 100.years) }, type: :date }
  validates :started_on, presence: true, timeliness: { on_or_after: ->(exchange) { exchange.financial_year_started_on }, type: :date }
  validates :format, presence: true
  do_not_validate_attachment_file_type :import_file

  scope :opened, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }
  scope :at, ->(date) { where('? BETWEEN started_on AND stopped_on', date) }

  enumerize :format, in: %i[ekylibre isacompta], default: :ekylibre, predicates: true, scope: true

  class << self
    def for_public_token(public_token)
      find_by!('public_token = ? AND public_token_expired_at >= ?', public_token, Time.zone.today)
    end
  end

  after_initialize :set_initial_values, if: :initializeable?
  after_create :set_journal_entries_financial_year_exchange

  def name
    "#{id.to_s} - #{started_on.to_s} | #{stopped_on.to_s}"
  end

  def opened?
    !closed_at
  end

  def close!
    ApplicationRecord.transaction do
      self.closed_at = Time.zone.now
      related_journal_entries.update_all(financial_year_exchange_id: nil)
      journals.update_all(financial_year_exchange_id: nil)
      save!
    end
  end

  def accountant_email
    return unless financial_year && financial_year.accountant

    address = financial_year.accountant.default_email_address
    address && address.coordinate
  end

  def accountant_email?
    accountant_email.present?
  end

  def generate_public_token!
    set_public_token_and_expiration
    save!
  end

  private

    delegate :stopped_on, :started_on, to: :financial_year, prefix: true, allow_nil: true

    def initializeable?
      new_record?
    end

    def any_opened_with_isacompta_format?
      opened.last.isacompta?
    end

    def set_initial_values
      if stopped_on.blank? && financial_year
        self.stopped_on = [Date.yesterday, financial_year.stopped_on].min
      end
    end

    def set_public_token_and_expiration
      self.public_token = SecureRandom.urlsafe_base64(32)
      self.public_token_expired_at = Time.zone.today + 1.month
    end

    def set_journal_entries_financial_year_exchange
      related_journal_entries.update_all(financial_year_exchange_id: id)
      Journal.where(id: exported_journal_ids).update_all(financial_year_exchange_id: id) if exported_journal_ids.any?
    end

    def related_journal_entries
      if exported_journal_ids.any?
        JournalEntry.joins(:journal).where(printed_on: started_on..stopped_on, journal_id: exported_journal_ids)
      else
        JournalEntry.joins(:journal).where(printed_on: started_on..stopped_on)
      end
    end
end
