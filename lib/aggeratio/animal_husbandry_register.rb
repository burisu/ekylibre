# frozen_string_literal: false

# Aggregator animal_husbandry_register: data exported as XML (printing) and HTML (preview).
# Formerly generated at boot from config/aggregators/animal_husbandry_register.xml.
module Aggeratio
  class AnimalHusbandryRegister < Aggregator
    # Translated properties (see rake clean:locales)
    PROPERTIES = %i[
      animal_husbandry_register
      enterprise
      entity_name
      address
      ede_cattling_number
      ede_owner_number
      name
      plan
      work_number
      area
      animal_productions
      started_on
      stopped_on
      born_at
      dead_at
      sex
      variety
      identification_number
      container_name
      started_at
      stopped_at
      prescription
      reference_number
      quantity
      unit_name
      meat_withdrawal_period
      milk_withdrawal_period
      meat_saleable_on
      milk_saleable_on
    ].freeze
    class << self
      def parameters
        [Parameter.new("campaigns", :record_list, {of: "campaign", default: "current"}).freeze, Parameter.new("started_on", :date, {default: "2013-01-01"}).freeze, Parameter.new("stopped_on", :date, {default: "2013-12-31"}).freeze].freeze
      end
      def aggregator_name
        'animal_husbandry_register'
      end
      alias :id :aggregator_name
      def category
        'animal_farming'
      end
    end
    def initialize(options = nil)
      options ||= {}
      if options['campaigns'].is_a?(String)
        @campaigns = Campaign.where(:id => options['campaigns'].to_s.split(/[\,\s]+/))
      elsif options['campaigns'].is_a?(Hash)
        @campaigns = Campaign.where(:id => options['campaigns'].select{|k,v| !v.to_i.zero?}.map(&:first))
      elsif options['campaigns'].is_a?(Array)
        @campaigns = Campaign.where(:id => options['campaigns'])
      else
        @campaigns = Campaign.current
      end
      @started_on = (options['started_on'] || "2013-01-01").to_date
      @stopped_on = (options['stopped_on'] || "2013-12-31").to_date
    end
    def to_xml(options = {})
      campaigns = @campaigns
      started_on = @started_on
      stopped_on = @stopped_on
      builder = Nokogiri::XML::Builder.new do |xml|
        # No elements
        attrs = {}
        xml.send('animal-husbandry-register', attrs) do
          company = Entity.of_company
          attrs = {}
          attrs['entity-name'] =         company.full_name
          if (company.default_mail_address)
            attrs['address'] =             company.default_mail_address.coordinate
          end
          if (Identifier.find_by_nature(:cattling_number))
            attrs['ede-cattling-number'] = Identifier.find_by_nature(:cattling_number).value
          end
          if (Identifier.find_by_nature(:husbandry_owner_number))
            attrs['ede-owner-number'] =    Identifier.find_by_nature(:husbandry_owner_number).value
          end
          xml.send('enterprise', attrs) do
            # No elements
          end
          for campaign in campaigns
            # No elements
            attrs = {}
            attrs['name'] = campaign.name
            xml.send('campaign', attrs) do
              animal_building_division = ProductNature.find_by(reference_name: :animal_building_division)
              attrs = {}
              attrs['plan-svg'] = BuildingDivision.of_nature(animal_building_division).shape_svg(srid: 2154)
              xml.send('plan', attrs) do
                for building_division in BuildingDivision.of_nature(animal_building_division)
                  # No elements
                  attrs = {}
                  attrs['name'] =                 building_division.name
                  attrs['work-number'] =          building_division.work_number
                  attrs['area'] =                 building_division.net_surface_area
                  attrs['area-in-square-meter'] = building_division.net_surface_area.in(:square_meter)
                  attrs['id'] =                   building_division.id
                  attrs['shape-svg'] =            building_division.shape_svg(srid: 2154)
                  xml.send('building-division', attrs) do
                    # No elements
                  end
                end
              end
              animal_activities = Activity.of_families(:animal_farming)
              attrs = {}
              xml.send('animal-productions', attrs) do
                for production in ActivityProduction.of_activities(animal_activities).of_campaign(campaign)
                  animal_ids = Product.where(activity_production: production).pluck(:id)
                  attrs = {}
                  attrs['name'] =       production.name
                  attrs['started-on'] = (production.started_on ? production.started_on.xmlschema : production.started_on)
                  attrs['stopped-on'] = (production.stopped_on ? production.stopped_on.xmlschema : production.stopped_on)
                  xml.send('production', attrs) do
                    animal_ids = Product.where(activity_production: production).pluck(:id)
                    for animal in Animal.where(id: animal_ids)
                      # No elements
                      attrs = {}
                      attrs['name'] =                  animal.name
                      if (animal.born_at)
                        attrs['born-at'] =               (animal.born_at ? animal.born_at.xmlschema : animal.born_at)
                      end
                      if (animal.dead_at)
                        attrs['dead-at'] =               (animal.dead_at ? animal.dead_at.xmlschema : animal.dead_at)
                      end
                      attrs['work-number'] =           animal.work_number
                      attrs['sex'] =                   animal.sex
                      attrs['variety'] =               animal.variety
                      attrs['identification-number'] = animal.identification_number
                      xml.send('animal', attrs) do
                        xml.send('animal-localizations') do
                          for localization in animal.localizations
                            # No elements
                            xml.send('localization') do
                              xml.send('id', localization.id)
                              if (localization.container)
                                xml.send('container-name', localization.container.name)
                              end
                              if (localization.started_at)
                                xml.send('started-at', (localization.started_at ? localization.started_at.xmlschema : localization.started_at))
                              end
                              if (localization.stopped_at)
                                xml.send('stopped-at', (localization.stopped_at ? localization.stopped_at.xmlschema : localization.stopped_at))
                              end
                            end
                          end
                        end
                        xml.send('animal-treatments') do
                          for intervention in Intervention.real.of_category(:animal_treating).with_generic_cast('target', animal)
                            # No elements
                            xml.send('intervention') do
                              xml.send('id', intervention.id)
                              if (intervention.prescription)
                                # No elements
                                attrs = {}
                                attrs['id'] =               intervention.prescription.id
                                attrs['reference-number'] = intervention.prescription.reference_number
                                attrs['name'] =             intervention.prescription.name
                                xml.send('prescription', attrs) do
                                  # No elements
                                end
                              end
                              xml.send('inputs') do
                                for input in intervention.inputs
                                  meat_withdrawal_period = input.product.meat_withdrawal_period
                                  milk_withdrawal_period = input.product.milk_withdrawal_period
                                  xml.send('input') do
                                    meat_withdrawal_period = input.product.meat_withdrawal_period
                                    milk_withdrawal_period = input.product.milk_withdrawal_period
                                    xml.send('id', input.id)
                                    xml.send('name', input.product.name)
                                    xml.send('variety', input.product.variety)
                                    xml.send('quantity', input.quantity.l)
                                    xml.send('unit-name', input.product.unit_name)
                                    xml.send('withdrawal-periods') do
                                      xml.send('meat-withdrawal-period', meat_withdrawal_period)
                                      xml.send('milk-withdrawal-period', milk_withdrawal_period)
                                    end
                                    xml.send('sale-dates') do
                                      xml.send('meat-saleable-on', ((intervention.stopped_at + meat_withdrawal_period.to_d.send(meat_withdrawal_period.unit)).to_time ? (intervention.stopped_at + meat_withdrawal_period.to_d.send(meat_withdrawal_period.unit)).to_time.xmlschema : (intervention.stopped_at + meat_withdrawal_period.to_d.send(meat_withdrawal_period.unit)).to_time))
                                      xml.send('milk-saleable-on', ((intervention.stopped_at + milk_withdrawal_period.to_d.send(milk_withdrawal_period.unit)).to_time ? (intervention.stopped_at + milk_withdrawal_period.to_d.send(milk_withdrawal_period.unit)).to_time.xmlschema : (intervention.stopped_at + milk_withdrawal_period.to_d.send(milk_withdrawal_period.unit)).to_time))
                                    end
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      return builder.to_xml
    end
    def to_html_fragment
      campaigns = @campaigns
      started_on = @started_on
      stopped_on = @stopped_on
      __doc__ = Nokogiri::HTML::DocumentFragment.parse('')
      builder = Nokogiri::HTML::Builder.with(__doc__) do |xml|
        xml.section do
          xml.div(:class => 'section-content') do
            xml.section do
              xml.div(:class => 'section-content') do
                company = Entity.of_company
                xml.dl do
                  xml.dd('aggregator_properties.entity_name'.t(default: [:'attributes.entity_name', :'labels.entity_name', :'activerecord.models.entity_name', "Entity name"]))
                  xml.dt({}) do
                    xml.text(company.full_name)
                  end
                end
                if (company.default_mail_address)
                  xml.dl do
                    xml.dd('aggregator_properties.address'.t(default: [:'attributes.address', :'labels.address', :'activerecord.models.address', "Address"]))
                    xml.dt({}) do
                      xml.text(company.default_mail_address.coordinate)
                    end
                  end
                end
                if (Identifier.find_by_nature(:cattling_number))
                  xml.dl do
                    xml.dd('aggregator_properties.ede_cattling_number'.t(default: [:'attributes.ede_cattling_number', :'labels.ede_cattling_number', :'activerecord.models.ede_cattling_number', "Ede cattling number"]))
                    xml.dt({}) do
                      xml.text(Identifier.find_by_nature(:cattling_number).value)
                    end
                  end
                end
                if (Identifier.find_by_nature(:husbandry_owner_number))
                  xml.dl do
                    xml.dd('aggregator_properties.ede_owner_number'.t(default: [:'attributes.ede_owner_number', :'labels.ede_owner_number', :'activerecord.models.ede_owner_number', "Ede owner number"]))
                    xml.dt({}) do
                      xml.text(Identifier.find_by_nature(:husbandry_owner_number).value)
                    end
                  end
                end
              end
            end
            for campaign in campaigns
              xml.section do
                xml.div(:class => 'section-content') do
                  xml.dl do
                    xml.dd('aggregator_properties.name'.t(default: [:'attributes.name', :'labels.name', :'activerecord.models.name', "Name"]))
                    xml.dt({}) do
                      xml.text(campaign.name)
                    end
                  end
                  xml.section do
                    xml.div(:class => 'section-content') do
                      animal_building_division = ProductNature.find_by(reference_name: :animal_building_division)
                      for building_division in BuildingDivision.of_nature(animal_building_division)
                        xml.section do
                          xml.h1 do
                            xml.span('aggregator_properties.building_division'.t(default: [:'attributes.building_division', :'labels.building_division', :'activerecord.models.building_division', 'Building division']))
                            xml.text(' ')
                            xml.em({}) do
                              if building_division.class < ApplicationRecord
                                xml.a(:href => "/backend/#{building_division.class.table_name}/#{building_division.to_param}") do
                                  xml.text(building_division.name)
                                end
                              else
                                xml.text(building_division.name)
                              end
                            end
                          end
                          xml.div(:class => 'section-content') do
                            xml.dl do
                              xml.dd('aggregator_properties.work_number'.t(default: [:'attributes.work_number', :'labels.work_number', :'activerecord.models.work_number', "Work number"]))
                              xml.dt({}) do
                                if building_division.class < ApplicationRecord
                                  xml.a(:href => "/backend/#{building_division.class.table_name}/#{building_division.to_param}") do
                                    xml.text(building_division.work_number)
                                  end
                                else
                                  xml.text(building_division.work_number)
                                end
                              end
                            end
                            xml.dl do
                              xml.dd('aggregator_properties.area'.t(default: [:'attributes.area', :'labels.area', :'activerecord.models.area', "Area"]))
                              xml.dt({}) do
                                xml.text(building_division.net_surface_area.l) unless building_division.net_surface_area.nil?
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                  xml.section do
                    xml.div(:class => 'section-content') do
                      animal_activities = Activity.of_families(:animal_farming)
                      for production in ActivityProduction.of_activities(animal_activities).of_campaign(campaign)
                        xml.section do
                          xml.h1 do
                            xml.span('aggregator_properties.production'.t(default: [:'attributes.production', :'labels.production', :'activerecord.models.production', 'Production']))
                            xml.text(' ')
                            xml.em({}) do
                              if production.class < ApplicationRecord
                                xml.a(:href => "/backend/#{production.class.table_name}/#{production.to_param}") do
                                  xml.text(production.name)
                                end
                              else
                                xml.text(production.name)
                              end
                            end
                          end
                          xml.div(:class => 'section-content') do
                            xml.dl do
                              xml.dd('aggregator_properties.started_on'.t(default: [:'attributes.started_on', :'labels.started_on', :'activerecord.models.started_on', "Started on"]))
                              xml.dt({}) do
                                if production.class < ApplicationRecord
                                  xml.a(:href => "/backend/#{production.class.table_name}/#{production.to_param}") do
                                    xml.text(production.started_on.l) unless production.started_on.nil?
                                  end
                                else
                                  xml.text(production.started_on.l) unless production.started_on.nil?
                                end
                              end
                            end
                            xml.dl do
                              xml.dd('aggregator_properties.stopped_on'.t(default: [:'attributes.stopped_on', :'labels.stopped_on', :'activerecord.models.stopped_on', "Stopped on"]))
                              xml.dt({}) do
                                if production.class < ApplicationRecord
                                  xml.a(:href => "/backend/#{production.class.table_name}/#{production.to_param}") do
                                    xml.text(production.stopped_on.l) unless production.stopped_on.nil?
                                  end
                                else
                                  xml.text(production.stopped_on.l) unless production.stopped_on.nil?
                                end
                              end
                            end
                            animal_ids = Product.where(activity_production: production).pluck(:id)
                            for animal in Animal.where(id: animal_ids)
                              xml.section do
                                xml.h1 do
                                  xml.span('aggregator_properties.animal'.t(default: [:'attributes.animal', :'labels.animal', :'activerecord.models.animal', 'Animal']))
                                  xml.text(' ')
                                  xml.em({}) do
                                    if animal.class < ApplicationRecord
                                      xml.a(:href => "/backend/#{animal.class.table_name}/#{animal.to_param}") do
                                        xml.text(animal.name)
                                      end
                                    else
                                      xml.text(animal.name)
                                    end
                                  end
                                end
                                xml.div(:class => 'section-content') do
                                  if (animal.born_at)
                                    xml.dl do
                                      xml.dd('aggregator_properties.born_at'.t(default: [:'attributes.born_at', :'labels.born_at', :'activerecord.models.born_at', "Born at"]))
                                      xml.dt({}) do
                                        if animal.class < ApplicationRecord
                                          xml.a(:href => "/backend/#{animal.class.table_name}/#{animal.to_param}") do
                                            xml.text(animal.born_at.l) unless animal.born_at.nil?
                                          end
                                        else
                                          xml.text(animal.born_at.l) unless animal.born_at.nil?
                                        end
                                      end
                                    end
                                  end
                                  if (animal.dead_at)
                                    xml.dl do
                                      xml.dd('aggregator_properties.dead_at'.t(default: [:'attributes.dead_at', :'labels.dead_at', :'activerecord.models.dead_at', "Dead at"]))
                                      xml.dt({}) do
                                        if animal.class < ApplicationRecord
                                          xml.a(:href => "/backend/#{animal.class.table_name}/#{animal.to_param}") do
                                            xml.text(animal.dead_at.l) unless animal.dead_at.nil?
                                          end
                                        else
                                          xml.text(animal.dead_at.l) unless animal.dead_at.nil?
                                        end
                                      end
                                    end
                                  end
                                  xml.dl do
                                    xml.dd('aggregator_properties.work_number'.t(default: [:'attributes.work_number', :'labels.work_number', :'activerecord.models.work_number', "Work number"]))
                                    xml.dt({}) do
                                      if animal.class < ApplicationRecord
                                        xml.a(:href => "/backend/#{animal.class.table_name}/#{animal.to_param}") do
                                          xml.text(animal.work_number)
                                        end
                                      else
                                        xml.text(animal.work_number)
                                      end
                                    end
                                  end
                                  xml.dl do
                                    xml.dd('aggregator_properties.sex'.t(default: [:'attributes.sex', :'labels.sex', :'activerecord.models.sex', "Sex"]))
                                    xml.dt({}) do
                                      if animal.class < ApplicationRecord
                                        xml.a(:href => "/backend/#{animal.class.table_name}/#{animal.to_param}") do
                                          xml.text(animal.sex)
                                        end
                                      else
                                        xml.text(animal.sex)
                                      end
                                    end
                                  end
                                  xml.dl do
                                    xml.dd('aggregator_properties.variety'.t(default: [:'attributes.variety', :'labels.variety', :'activerecord.models.variety', "Variety"]))
                                    xml.dt({}) do
                                      if animal.class < ApplicationRecord
                                        xml.a(:href => "/backend/#{animal.class.table_name}/#{animal.to_param}") do
                                          xml.text(animal.variety)
                                        end
                                      else
                                        xml.text(animal.variety)
                                      end
                                    end
                                  end
                                  xml.dl do
                                    xml.dd('aggregator_properties.identification_number'.t(default: [:'attributes.identification_number', :'labels.identification_number', :'activerecord.models.identification_number', "Identification number"]))
                                    xml.dt({}) do
                                      if animal.class < ApplicationRecord
                                        xml.a(:href => "/backend/#{animal.class.table_name}/#{animal.to_param}") do
                                          xml.text(animal.identification_number)
                                        end
                                      else
                                        xml.text(animal.identification_number)
                                      end
                                    end
                                  end
                                  xml.table(:class => 'matrix') do
                                    xml.thead do
                                      xml.tr do
                                        xml.th('aggregator_properties.container_name'.t(default: [:'attributes.container_name', :'labels.container_name', :'activerecord.models.container_name', "Container name"]), :class => 'container-name')
                                        xml.th('aggregator_properties.started_at'.t(default: [:'attributes.started_at', :'labels.started_at', :'activerecord.models.started_at', "Started at"]), :class => 'started-at')
                                        xml.th('aggregator_properties.stopped_at'.t(default: [:'attributes.stopped_at', :'labels.stopped_at', :'activerecord.models.stopped_at', "Stopped at"]), :class => 'stopped-at')
                                      end
                                    end
                                    xml.tbody do
                                      for localization in animal.localizations
                                        # No elements
                                        xml.tr do
                                          xml.td(:class => 'container-name') do
                                            if (localization.container)
                                              xml.text(localization.container.name)
                                            end
                                          end
                                          xml.td(:class => 'started-at') do
                                            if (localization.started_at)
                                              xml.text(localization.started_at.l) unless localization.started_at.nil?
                                            end
                                          end
                                          xml.td(:class => 'stopped-at') do
                                            if (localization.stopped_at)
                                              xml.text(localization.stopped_at.l) unless localization.stopped_at.nil?
                                            end
                                          end
                                        end
                                      end
                                    end
                                  end
                                  xml.table(:class => 'matrix') do
                                    xml.thead do
                                      xml.tr do
                                        xml.th(:class => 'matrix inputs') do
                                          xml.table(:class => 'matrix') do
                                            xml.thead do
                                              xml.tr do
                                                xml.th('aggregator_properties.name'.t(default: [:'attributes.name', :'labels.name', :'activerecord.models.name', "Name"]), :class => 'name')
                                              end
                                              xml.tr do
                                                xml.th('aggregator_properties.quantity'.t(default: [:'attributes.quantity', :'labels.quantity', :'activerecord.models.quantity', "Quantity"]), :class => 'quantity')
                                              end
                                              xml.tr do
                                                xml.th('aggregator_properties.unit_name'.t(default: [:'attributes.unit_name', :'labels.unit_name', :'activerecord.models.unit_name', "Unit name"]), :class => 'unit-name')
                                              end
                                              xml.tr do
                                                xml.th(:class => 'matrix withdrawal-periods') do
                                                  xml.table(:class => 'matrix') do
                                                    xml.thead do
                                                      xml.tr do
                                                        xml.th('aggregator_properties.meat_withdrawal_period'.t(default: [:'attributes.meat_withdrawal_period', :'labels.meat_withdrawal_period', :'activerecord.models.meat_withdrawal_period', "Meat withdrawal period"]), :class => 'meat-withdrawal-period')
                                                        xml.th('aggregator_properties.milk_withdrawal_period'.t(default: [:'attributes.milk_withdrawal_period', :'labels.milk_withdrawal_period', :'activerecord.models.milk_withdrawal_period', "Milk withdrawal period"]), :class => 'milk-withdrawal-period')
                                                      end
                                                    end
                                                  end
                                                end
                                              end
                                              xml.tr do
                                                xml.th(:class => 'matrix sale-dates') do
                                                  xml.table(:class => 'matrix') do
                                                    xml.thead do
                                                      xml.tr do
                                                        xml.th('aggregator_properties.meat_saleable_on'.t(default: [:'attributes.meat_saleable_on', :'labels.meat_saleable_on', :'activerecord.models.meat_saleable_on', "Meat saleable on"]), :class => 'meat-saleable-on')
                                                        xml.th('aggregator_properties.milk_saleable_on'.t(default: [:'attributes.milk_saleable_on', :'labels.milk_saleable_on', :'activerecord.models.milk_saleable_on', "Milk saleable on"]), :class => 'milk-saleable-on')
                                                      end
                                                    end
                                                  end
                                                end
                                              end
                                            end
                                          end
                                        end
                                      end
                                    end
                                    xml.tbody do
                                      for intervention in Intervention.real.of_category(:animal_treating).with_generic_cast('target', animal)
                                        # No elements
                                        xml.tr do
                                          xml.td(:class => 'matrix inputs') do
                                            xml.table(:class => 'matrix') do
                                              xml.tbody do
                                                for input in intervention.inputs
                                                  meat_withdrawal_period = input.product.meat_withdrawal_period
                                                  milk_withdrawal_period = input.product.milk_withdrawal_period
                                                  xml.tr do
                                                    xml.td({class: "name"}) do
                                                      xml.text(input.product.name)
                                                    end
                                                  end
                                                  xml.tr do
                                                    xml.td({class: "quantity"}) do
                                                      xml.text(input.quantity.l.l) unless input.quantity.l.nil?
                                                    end
                                                  end
                                                  xml.tr do
                                                    xml.td({class: "unit-name"}) do
                                                      xml.text(input.product.unit_name)
                                                    end
                                                  end
                                                  xml.tr do
                                                    xml.td(:class => 'matrix withdrawal-periods') do
                                                      xml.table(:class => 'matrix') do
                                                        xml.tbody do
                                                          # No elements
                                                          xml.tr do
                                                            xml.td({class: "meat-withdrawal-period"}) do
                                                              xml.text(meat_withdrawal_period.l) unless meat_withdrawal_period.nil?
                                                            end
                                                            xml.td({class: "milk-withdrawal-period"}) do
                                                              xml.text(milk_withdrawal_period.l) unless milk_withdrawal_period.nil?
                                                            end
                                                          end
                                                        end
                                                      end
                                                    end
                                                  end
                                                  xml.tr do
                                                    xml.td(:class => 'matrix sale-dates') do
                                                      xml.table(:class => 'matrix') do
                                                        xml.tbody do
                                                          # No elements
                                                          xml.tr do
                                                            xml.td({class: "meat-saleable-on"}) do
                                                              xml.text((intervention.stopped_at + meat_withdrawal_period.to_d.send(meat_withdrawal_period.unit)).to_time.l) unless (intervention.stopped_at + meat_withdrawal_period.to_d.send(meat_withdrawal_period.unit)).to_time.nil?
                                                            end
                                                            xml.td({class: "milk-saleable-on"}) do
                                                              xml.text((intervention.stopped_at + milk_withdrawal_period.to_d.send(milk_withdrawal_period.unit)).to_time.l) unless (intervention.stopped_at + milk_withdrawal_period.to_d.send(milk_withdrawal_period.unit)).to_time.nil?
                                                            end
                                                          end
                                                        end
                                                      end
                                                    end
                                                  end
                                                end
                                              end
                                            end
                                          end
                                        end
                                      end
                                    end
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      return __doc__.to_html.html_safe
    end
  end
end
