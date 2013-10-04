# encoding: UTF-8
# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: product_natures
#
#  abilities              :text
#  active                 :boolean          not null
#  asset_account_id       :integer
#  charge_account_id      :integer
#  created_at             :datetime         not null
#  creator_id             :integer
#  depreciable            :boolean          not null
#  derivative_of          :string(120)
#  description            :text
#  id                     :integer          not null, primary key
#  indicators             :text
#  lock_version           :integer          default(0), not null
#  name                   :string(255)      not null
#  nomen                  :string(120)
#  number                 :string(30)       not null
#  population_counting    :string(255)      not null
#  product_account_id     :integer
#  purchasable            :boolean          not null
#  reductible             :boolean          not null
#  saleable               :boolean          not null
#  stock_account_id       :integer
#  storable               :boolean          not null
#  subscribing            :boolean          not null
#  subscription_duration  :string(255)
#  subscription_nature_id :integer
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variety                :string(120)      not null
#


class ProductNature < Ekylibre::Record::Base
  # attr_accessible :abilities, :active, :derivative_of, :description, :depreciable, :indicators, :purchasable, :saleable, :asset_account_id, :name, :nomen, :number, :population_counting, :stock_account_id, :charge_account_id, :product_account_id, :storable, :subscription_nature_id, :subscription_duration, :reductible, :subscribing, :variety
  enumerize :variety, :in => Nomen::Varieties.all, :predicates => {:prefix => true}
  # Be careful with the fact that it depends directly on the nomenclature definition
  enumerize :population_counting, :in => Nomen::ProductNatures.attributes[:population_counting].choices, :predicates => {:prefix => true}, :default => Nomen::ProductNatures.attributes[:population_counting].choices.first
  belongs_to :asset_account, :class_name => "Account"
  belongs_to :charge_account, :class_name => "Account"
  belongs_to :product_account, :class_name => "Account"
  belongs_to :stock_account, :class_name => "Account"
  belongs_to :subscription_nature
  has_and_belongs_to_many :sale_taxes, class_name: "Tax" # , join_table: 'product_natures_sale_taxes'
  has_and_belongs_to_many :purchase_taxes, class_name: "Tax" # , join_table: 'product_natures_purchase_taxes'
  # has_many :available_stocks, :class_name => "ProductStock", :conditions => ["quantity > 0"], :foreign_key => :product_id
  #has_many :prices, :foreign_key => :product_nature_id, :class_name => "ProductPriceTemplate"
  has_many :subscriptions, :foreign_key => :product_nature_id
  has_many :productions
  has_many :products, :foreign_key => :nature_id
  has_many :variants, :class_name => "ProductNatureVariant", :foreign_key => :nature_id, :inverse_of => :nature
  has_one :default_variant, -> { order(:id) }, :class_name => "ProductNatureVariant", :foreign_key => :nature_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :number, :allow_nil => true, :maximum => 30
  validates_length_of :derivative_of, :nomen, :variety, :allow_nil => true, :maximum => 120
  validates_length_of :name, :population_counting, :subscription_duration, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :depreciable, :purchasable, :reductible, :saleable, :storable, :subscribing, :in => [true, false]
  validates_presence_of :name, :number, :population_counting, :variety
  #]VALIDATORS]
  validates_presence_of :subscription_nature,   :if => :subscribing?
  validates_presence_of :subscription_period,   :if => Proc.new{|u| u.subscribing? and u.subscription_nature and u.subscription_nature.period? }
  validates_presence_of :subscription_quantity, :if => Proc.new{|u| u.subscribing? and u.subscription_nature and u.subscription_nature.quantity? }
  validates_presence_of :product_account, :if => :saleable?
  validates_presence_of :charge_account,  :if => :purchasable?
  validates_presence_of :stock_account,   :if => :storable?
  validates_presence_of :asset_account,   :if => :depreciable?
  validates_uniqueness_of :number
  validates_uniqueness_of :name

  accepts_nested_attributes_for :variants, :reject_if => :all_blank, :allow_destroy => true
  acts_as_numbered :force => false

  # default_scope -> { order(:name) }
  scope :availables, -> { where(:active => true).order(:name) }
  scope :stockables, -> { where(:storable => true).order(:name) }
  scope :saleables, -> { where(:saleable => true).order(:name) }
  scope :purchaseables, -> { where(:purchasable => true).order(:name) }
  # scope :producibles, -> { where(:variety => ["bos", "animal", "plant", "organic_matter"]).order(:name) }

  scope :of_variety, Proc.new { |*varieties|
    where(:variety => varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :derivative_of, Proc.new { |*varieties|
    where(:derivative_of => varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  # scope :of_variety, Proc.new { |*varieties| where(:variety => varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq) }

  # scope :derivative_of, lambda { |nature|
  #   raise ArgumentError.new("Expected Product Nature, got #{nature.class.name}:#{nature.inspect}") unless nature.is_a?(ProductNature)
  #   where(:derivative_of => nature.variety)
  # }

  before_validation do
    if self.derivative_of
      self.variety ||= self.derivative_of
    end
    self.derivative_of = nil if self.variety.to_s == self.derivative_of.to_s
    unless self.indicators_array.detect{|i| i.name.to_sym == :population}
      self.indicators ||= ""
      self.indicators << " population"
    end
    self.indicators = self.indicators_array.map(&:name).sort.join(", ")
    self.abilities  = self.abilities_array.sort.join(", ")
    self.storable = false unless self.deliverable?
    self.subscription_nature_id = nil unless self.subscribing?
    return true
  end

  # Returns the closest matching model based on the given variety
  def self.matching_model(variety)
    if item = Nomen::Varieties.find(variety)
      for ancestor in item.self_and_parents
        if model = ancestor.name.camelcase.constantize rescue nil
          return model if model <= Product
        end
      end
    end
    return nil
  end

  # Returns the matching model for the record
  def matching_model
    return self.class.matching_model(self.variety)
  end

  # Returns if population is frozen
  def population_frozen?
    return self.population_counting_unitary?
  end

  # Returns the minimum couting element
  def population_modulo
    return (self.population_counting_decimal? ? 0.0001 : 1)
  end

  # Returns list of indicators as an array of indicator items from the nomenclature
  def indicators_array
    return self.indicators.to_s.strip.split(/[\,\s]/).collect do |i|
      Nomen::Indicators[i]
    end.compact
  end

  # Returns list of abilities as an array of ability items from the nomenclature
  def abilities_array
    return self.abilities.to_s.strip.split(/[\,\s]/).collect do |i|
      (Nomen::Abilities[i.split(/\(/).first] ? i : nil)
    end.compact
  end

  def to
    to = []
    to << :sales if self.saleable?
    to << :purchases if self.purchasable?
    # to << :produce if self.producible?
    to.collect{|x| tc('to.'+x.to_s)}.to_sentence
  end

  def deliverable?
    self.storable?
  end


  # # Returns the default
  # def default_price(options)
  #   price = nil
  #   if template = self.templates.where(:listing_id => listing_id, :active => true, :by_default => true).first
  #     price = template.price
  #   end
  #   return price
  # end

  def label
    tc('label', :product_nature => self["name"])
  end

  def informations
    tc('informations.without_components', :product_nature => self.name, :unit => self.unit.label, :size => self.components.size)
  end

  def duration
    #raise Exception.new self.subscription_nature.nature.inspect+" blabla"
    if self.subscription_nature
      self.send('subscription_'+self.subscription_nature.nature)
    else
      return nil
    end

  end

  def duration=(value)
    #raise Exception.new subscription.inspect+self.subscription_nature_id.inspect
    if self.subscription_nature
      self.send('subscription_'+self.subscription_nature.nature+'=', value)
    end
  end

  def default_start
    # self.subscription_nature.nature == "period" ? Date.today.beginning_of_year : self.subscription_nature.actual_number
    self.subscription_nature.nature == "period" ? Date.today : self.subscription_nature.actual_number
  end

  def default_finish
    period = self.subscription_period || '1 year'
    # self.subscription_nature.nature == "period" ? Date.today.next_year.beginning_of_year.next_month.end_of_month : (self.subscription_nature.actual_number + ((self.subscription_quantity-1)||0))
    self.subscription_nature.nature == "period" ? Delay.compute(period+", 1 day ago", Date.today) : (self.subscription_nature.actual_number + ((self.subscription_quantity-1)||0))
  end

  def default_subscription_label_for(entity)
    return nil unless self.nature == "subscrip"
    entity  = nil unless entity.is_a? Entity
    address = entity.default_contact.address rescue nil
    entity = entity.full_name rescue "???"
    if self.subscription_nature.nature == "period"
      return tc('subscription_label.period', :start => ::I18n.localize(Date.today), :finish => ::I18n.localize(Delay.compute(self.subscription_period.blank? ? '1 year, 1 day ago' : self.product.subscription_period)), :entity => entity, :address => address, :subscription_nature => self.subscription_nature.name)
    elsif self.subscription_nature.nature == "quantity"
      return tc('subscription_label.quantity', :start => self.subscription_nature.actual_number.to_i, :finish => (self.subscription_nature.actual_number.to_i + ((self.subscription_quantity-1)||0)), :entity => entity, :address => address, :subscription_nature => self.subscription_nature.name)
    end
  end

  # # TODO : move stock methods in operation / product
  # # Create real stocks moves to update the real state of stocks
  # def move_outgoing_stock(options={})
  #   add_stock_move(options.merge(:virtual => false, :incoming => false))
  # end

  # def move_incoming_stock(options={})
  #   add_stock_move(options.merge(:virtual => false, :incoming => true))
  # end

  # # Create virtual stock moves to reserve the products
  # def reserve_outgoing_stock(options={})
  #   add_stock_move(options.merge(:virtual => true, :incoming => false))
  # end

  # def reserve_incoming_stock(options={})
  #   add_stock_move(options.merge(:virtual => true, :incoming => true))
  # end

  # # Create real stocks moves to update the real state of stocks
  # def move_stock(options={})
  #   add_stock_move(options.merge(:virtual => false))
  # end

  # # Create virtual stock moves to reserve the products
  # def reserve_stock(options={})
  #   add_stock_move(options.merge(:virtual => true))
  # end

  # # Generic method to add stock move in product's stock
  # def add_stock_move(options={})
  #   return true unless self.stockable?
  #   incoming = options.delete(:incoming)
  #   attributes = options.merge(:generated => true)
  #   origin = options[:origin]
  #   if origin.is_a? ActiveRecord::Base
  #     code = [:number, :code, :name, :id].detect{|x| origin.respond_to? x}
  #     attributes[:name] = tc('stock_move', :origin => (origin ? ::I18n.t("activerecord.models.#{origin.class.name.underscore}") : "*"), :code => (origin ? origin.send(code) : "*"))
  #     for attribute in [:quantity, :unit, :tracking_id, :building_id, :product_id]
  #       unless attributes.keys.include? attribute
  #         attributes[attribute] ||= origin.send(attribute) rescue nil
  #       end
  #     end
  #   end
  #   attributes[:quantity] = -attributes[:quantity] unless incoming
  #   attributes[:building_id] ||= self.stocks.first.building_id if self.stocks.size > 0
  #   attributes[:planned_on] ||= Date.today
  #   attributes[:moved_on] ||= attributes[:planned_on] unless attributes.keys.include? :moved_on
  #   self.stock_moves.create!(attributes)
  # end


  # Load a product nature from product nature nomenclature
  def self.import_from_nomenclature(nomen)
    unless item = Nomen::ProductNatures.find(nomen)
      raise ArgumentError.new("The product_nature #{nomen.inspect} is not known")
    end
    unless nature = ProductNature.find_by_nomen(nomen)
      attributes = {
        :variety => item.variety,
        :abilities => item.abilities.sort.join(" "),
        :active => true,
        :name => item.human_name,
        :population_counting => item.population_counting,
        :nomen => item.name,
        :indicators => item.indicators.sort.join(" "),
        :derivative_of => item.derivative_of.to_s,
        :depreciable => item.depreciable,
        :purchasable => item.purchasable,
        :reductible => item.reductible,
        :saleable => item.saleable,
        :storable => item.storable
      }
      for account in [:asset, :charge, :product, :stock]
        if name = item.send("#{account}_account")
          attributes[:"#{account}_account_id"] = Account.find_or_create_in_chart(name).id
        end
      end
      nature = self.create!(attributes)
    end

    if nature.variants.count.zero?
      if item.unit_name
        variant = nature.variants.create!(:active => true, :unit_name => item.unit_name)
        if !item.frozen_indicators.to_s.blank?
          # transform "population: 1unity, net_weight :5ton" in a hash
          h_frozen_indicators = item.frozen_indicators.to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
            h[i.first.strip.downcase.to_sym] = i.second
            h
            }
          # create frozen indicator for each pair indicator, value ":population => 1unity"
          for indicator, value in h_frozen_indicators
            variant.is_measured!(indicator, value)
          end
        end
      else
        raise ArgumentError.new("The unit_name #{item.unit_name.inspect} of product_nature #{item.name} is not known")
      end
    end
    return nature
  end

  # Load.all product nature from product nature nomenclature
  def self.import_all_from_nomenclature
    for product_nature in Nomen::ProductNatures.all
      import_from_nomenclature(product_nature)
    end
  end

end
