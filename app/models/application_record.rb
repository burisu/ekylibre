# frozen_string_literal: true

require_dependency 'ekylibre/record/acts/affairable'
require_dependency 'ekylibre/record/acts/numbered'
require_dependency 'ekylibre/record/acts/picturable'
require_dependency 'ekylibre/record/acts/protected'
require_dependency 'ekylibre/record/acts/reconcilable'
require_dependency 'ekylibre/record/acts/referable'
require_dependency 'ekylibre/record/autosave'
require_dependency 'ekylibre/record/bookkeep'
require_dependency 'ekylibre/record/dependents'
require_dependency 'ekylibre/record/has_shape'
require_dependency 'ekylibre/record/selects_among_all'
require_dependency 'ekylibre/record/sums'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  prepend IdHumanizable

  include Ekylibre::Record::Acts::Affairable
  include Ekylibre::Record::Acts::Numbered
  include Ekylibre::Record::Acts::Picturable
  include Ekylibre::Record::Acts::Protected
  include Ekylibre::Record::Acts::Reconcilable
  include Ekylibre::Record::Acts::Referable

  include Ekylibre::Record::Autosave
  include Ekylibre::Record::Bookkeep
  include Ekylibre::Record::Dependents
  include Ekylibre::Record::HasShape
  include Ekylibre::Record::SelectsAmongAll
  include Ekylibre::Record::Sums

  include ConditionalReadonly
  include ScopeIntrospection
  include Userstamp::Stamper
  include Userstamp::Stampable
  include HasInterval

  self.abstract_class = true

  # Permits to use enumerize in all models
  extend Enumerize

  # Make all models stampables
  stampable

  def editable?
    updateable?
  end

  def self.customizable?
    respond_to?(:custom_fields)
  end

  def customizable?
    self.class.customizable?
  end

  def customized?
    customizable? && self.class.custom_fields.any?
  end

  def human_attribute_name(*args)
    self.class.human_attribute_name(*args)
  end

  # Returns a relation for all other records
  def others
    self.class.where.not(id: (id || -1))
  end

  # Returns a relation for the old record in DB
  def old_record
    if new_record?
      nil
    else
      self.class.find_by(id: id)
    end
  end

  def already_updated?
    self.class.where(id: id, lock_version: lock_version).empty?
  end

  def unsuppress
    yield
  rescue ActiveRecord::RecordInvalid => would_be_silently_dropped
    Rails.logger.info would_be_silently_dropped.inspect
    wont_be_dropped = Ekylibre::Record::RecordInvalid.new(would_be_silently_dropped.message,
                                                          would_be_silently_dropped.record)
    wont_be_dropped.set_backtrace(would_be_silently_dropped.backtrace)
    raise wont_be_dropped
  end

  # Allow to grab old / new attribute from a resource object to have the history aka versioning
  # ex : e = Entity.find(1) // resource object
  # e.client_payment_mode // object on resource object
  # e.name // value on resource object
  def human_changed_attribute_value(change, state)
    att = change.attribute.gsub(/_id$/, '')
    value_retrievable = change.attribute.match(/_id$/) && respond_to?(att) && send(att).respond_to?('name')
    # if value is retrievable (object on resource object) from resource object and state new, we grab it from resource object
    if value_retrievable && state == 'new'
      (send(att).respond_to?('label') ? send(att).label : send(att).name).to_s
    # if value is retrievable from resource object and state old, we grab his id from change object
    elsif value_retrievable && state == 'old'
      old_rec = send(att).model_name.name.constantize.find(change.send("human_#{state}_value"))
      (old_rec.respond_to?('label') ? old_rec.label : old_rec.name).to_s
    # we grad value directly from change object (value on resource object)
    else
      change.send("human_#{state}_value")
    end
  end

  class << self
    attr_accessor :readonly_counter

    def columns_definition
      Ekylibre::Schema.tables[table_name] || {}.with_indifferent_access
    end
  end
end
