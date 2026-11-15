# frozen_string_literal: false

# Aggregator veterinary_booklet: data exported as XML (printing) and HTML (preview).
# Formerly generated at boot from config/aggregators/veterinary_booklet.xml.
module Aggeratio
  class VeterinaryBooklet < Aggregator
    # Translated properties (see rake clean:locales)
    PROPERTIES = %i[
      campaigns
      entity_name
      address
      breeding_number
      name
      started_at
      stopped_at
      working_duration
      identification_number
      issue
      nature
      observed_at
      description
      picture_path
      prescription
      reference_number
      variant_name
      quantity
      meat_withdrawal_period
      milk_withdrawal_period
      meat_saleable_on
      milk_saleable_on
    ].freeze
    class << self
      def parameters
        [Parameter.new("campaigns", :record_list, {of: "campaign", default: "current"}).freeze].freeze
      end
      def aggregator_name
        'veterinary_booklet'
      end
      alias :id :aggregator_name
      def category
        'health'
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
    end
    def to_xml(options = {})
      campaigns = @campaigns
      builder = Nokogiri::XML::Builder.new do |xml|
        if (Entity.of_company)
          company = Entity.of_company
        end
        attrs = {}
        if (company)
          attrs['entity-name'] =     company.full_name
        end
        if (company)
          attrs['address'] =         company.default_mail_address.coordinate
        end
        if (Identifier.find_by_nature(:cattling_number))
          attrs['breeding-number'] = Identifier.find_by_nature(:cattling_number).value
        end
        xml.send('campaigns', attrs) do
          for campaign in campaigns
            targets = Animal.available
            attrs = {}
            attrs['id'] =   campaign.id
            attrs['name'] = campaign.name
            xml.send('campaign', attrs) do
              targets = Animal.available
              for intervention in Intervention.real.of_civil_year(campaign.harvest_year).of_category(:animal_treating).with_targets(targets).reorder(:started_at)
                # No elements
                attrs = {}
                attrs['name'] =                 intervention.name
                attrs['id'] =                   intervention.id
                attrs['url'] =                  "#{Ekylibre::Tenant.host}/backend/interventions/#{intervention.id}"
                attrs['started-at'] =           (intervention.started_at ? intervention.started_at.xmlschema : intervention.started_at)
                attrs['stopped-at'] =           (intervention.stopped_at ? intervention.stopped_at.xmlschema : intervention.stopped_at)
                attrs['working-duration'] =     intervention.working_duration.in(:second).in(:hour).round(2).l
                attrs['targets-product-name'] = intervention.human_target_names
                attrs['doers-product-name'] =   intervention.human_doer_names
                xml.send('intervention', attrs) do
                  xml.send('target') do
                    for target in intervention.targets
                      # No elements
                      xml.send('target') do
                        xml.send('name', target.product.name)
                        xml.send('identification-number', target.product.identification_number)
                        xml.send('id', target.product.id)
                      end
                    end
                  end
                  xml.send('worker') do
                    for worker in intervention.doers
                      # No elements
                      xml.send('worker') do
                        xml.send('name', worker.product.name)
                        xml.send('identification-number', worker.product.identification_number)
                      end
                    end
                  end
                  if (intervention.issue)
                    # No elements
                    attrs = {}
                    attrs['id'] =                  intervention.issue.id
                    attrs['nature'] =              intervention.issue.nature
                    attrs['name'] =                intervention.issue.name
                    attrs['observed-at'] =         (intervention.issue.observed_at ? intervention.issue.observed_at.xmlschema : intervention.issue.observed_at)
                    attrs['state'] =               intervention.issue.state
                    attrs['interventions-count'] = intervention.issue.interventions_count
                    attrs['description'] =         intervention.issue.description
                    attrs['picture-path'] =        intervention.issue.picture_path
                    xml.send('issue', attrs) do
                      # No elements
                    end
                  end
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
                        xml.send('variant-name', input.product.variant_name)
                        xml.send('quantity', input.quantity.l)
                        xml.send('variety', input.product.variety)
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
      return builder.to_xml
    end
    def to_html_fragment
      campaigns = @campaigns
      __doc__ = Nokogiri::HTML::DocumentFragment.parse('')
      builder = Nokogiri::HTML::Builder.with(__doc__) do |xml|
        xml.section do
          xml.div(:class => 'section-content') do
            if (Entity.of_company)
              company = Entity.of_company
            end
            if (company)
              xml.dl do
                xml.dd('aggregator_properties.entity_name'.t(default: [:'attributes.entity_name', :'labels.entity_name', :'activerecord.models.entity_name', "Entity name"]))
                xml.dt({}) do
                  xml.text(company.full_name)
                end
              end
            end
            if (company)
              xml.dl do
                xml.dd('aggregator_properties.address'.t(default: [:'attributes.address', :'labels.address', :'activerecord.models.address', "Address"]))
                xml.dt({}) do
                  xml.text(company.default_mail_address.coordinate)
                end
              end
            end
            if (Identifier.find_by_nature(:cattling_number))
              xml.dl do
                xml.dd('aggregator_properties.breeding_number'.t(default: [:'attributes.breeding_number', :'labels.breeding_number', :'activerecord.models.breeding_number', "Breeding number"]))
                xml.dt({}) do
                  xml.text(Identifier.find_by_nature(:cattling_number).value)
                end
              end
            end
            for campaign in campaigns
              xml.section do
                xml.h1 do
                  xml.span('aggregator_properties.campaign'.t(default: [:'attributes.campaign', :'labels.campaign', :'activerecord.models.campaign', 'Campaign']))
                  xml.text(' ')
                  xml.em({}) do
                    xml.text(campaign.name)
                  end
                end
                xml.div(:class => 'section-content') do
                  targets = Animal.available
                  for intervention in Intervention.real.of_civil_year(campaign.harvest_year).of_category(:animal_treating).with_targets(targets).reorder(:started_at)
                    xml.section do
                      xml.h1 do
                        xml.span('aggregator_properties.intervention'.t(default: [:'attributes.intervention', :'labels.intervention', :'activerecord.models.intervention', 'Intervention']))
                        xml.text(' ')
                        xml.em({}) do
                          if intervention.class < ApplicationRecord
                            xml.a(:href => "/backend/#{intervention.class.table_name}/#{intervention.to_param}") do
                              xml.text(intervention.name)
                            end
                          else
                            xml.text(intervention.name)
                          end
                        end
                      end
                      xml.div(:class => 'section-content') do
                        xml.dl do
                          xml.dd('aggregator_properties.started_at'.t(default: [:'attributes.started_at', :'labels.started_at', :'activerecord.models.started_at', "Started at"]))
                          xml.dt({}) do
                            if intervention.class < ApplicationRecord
                              xml.a(:href => "/backend/#{intervention.class.table_name}/#{intervention.to_param}") do
                                xml.text(intervention.started_at.l) unless intervention.started_at.nil?
                              end
                            else
                              xml.text(intervention.started_at.l) unless intervention.started_at.nil?
                            end
                          end
                        end
                        xml.dl do
                          xml.dd('aggregator_properties.stopped_at'.t(default: [:'attributes.stopped_at', :'labels.stopped_at', :'activerecord.models.stopped_at', "Stopped at"]))
                          xml.dt({}) do
                            if intervention.class < ApplicationRecord
                              xml.a(:href => "/backend/#{intervention.class.table_name}/#{intervention.to_param}") do
                                xml.text(intervention.stopped_at.l) unless intervention.stopped_at.nil?
                              end
                            else
                              xml.text(intervention.stopped_at.l) unless intervention.stopped_at.nil?
                            end
                          end
                        end
                        xml.dl do
                          xml.dd('aggregator_properties.working_duration'.t(default: [:'attributes.working_duration', :'labels.working_duration', :'activerecord.models.working_duration', "Working duration"]))
                          xml.dt({}) do
                            xml.text(intervention.working_duration.in(:second).in(:hour).round(2).l.l) unless intervention.working_duration.in(:second).in(:hour).round(2).l.nil?
                          end
                        end
                        xml.table(:class => 'matrix') do
                          xml.thead do
                            xml.tr do
                              xml.th('aggregator_properties.name'.t(default: [:'attributes.name', :'labels.name', :'activerecord.models.name', "Name"]), :class => 'name')
                              xml.th('aggregator_properties.identification_number'.t(default: [:'attributes.identification_number', :'labels.identification_number', :'activerecord.models.identification_number', "Identification number"]), :class => 'identification-number')
                            end
                          end
                          xml.tbody do
                            for target in intervention.targets
                              # No elements
                              xml.tr do
                                xml.td({class: "name"}) do
                                  xml.text(target.product.name)
                                end
                                xml.td({class: "identification-number"}) do
                                  xml.text(target.product.identification_number)
                                end
                              end
                            end
                          end
                        end
                        xml.table(:class => 'matrix') do
                          xml.thead do
                            xml.tr do
                              xml.th('aggregator_properties.name'.t(default: [:'attributes.name', :'labels.name', :'activerecord.models.name', "Name"]), :class => 'name')
                              xml.th('aggregator_properties.identification_number'.t(default: [:'attributes.identification_number', :'labels.identification_number', :'activerecord.models.identification_number', "Identification number"]), :class => 'identification-number')
                            end
                          end
                          xml.tbody do
                            for worker in intervention.doers
                              # No elements
                              xml.tr do
                                xml.td({class: "name"}) do
                                  xml.text(worker.product.name)
                                end
                                xml.td({class: "identification-number"}) do
                                  xml.text(worker.product.identification_number)
                                end
                              end
                            end
                          end
                        end
                        if (intervention.issue)
                          xml.section do
                            xml.h1 do
                              xml.span('aggregator_properties.issue'.t(default: [:'attributes.issue', :'labels.issue', :'activerecord.models.issue', 'Issue']))
                              xml.text(' ')
                              xml.em({}) do
                                if intervention.issue.class < ApplicationRecord
                                  xml.a(:href => "/backend/#{intervention.issue.class.table_name}/#{intervention.issue.to_param}") do
                                    xml.text(intervention.issue.nature)
                                  end
                                else
                                  xml.text(intervention.issue.nature)
                                end
                              end
                            end
                            xml.div(:class => 'section-content') do
                              xml.dl do
                                xml.dd('aggregator_properties.name'.t(default: [:'attributes.name', :'labels.name', :'activerecord.models.name', "Name"]))
                                xml.dt({}) do
                                  if intervention.issue.class < ApplicationRecord
                                    xml.a(:href => "/backend/#{intervention.issue.class.table_name}/#{intervention.issue.to_param}") do
                                      xml.text(intervention.issue.name)
                                    end
                                  else
                                    xml.text(intervention.issue.name)
                                  end
                                end
                              end
                              xml.dl do
                                xml.dd('aggregator_properties.observed_at'.t(default: [:'attributes.observed_at', :'labels.observed_at', :'activerecord.models.observed_at', "Observed at"]))
                                xml.dt({}) do
                                  if intervention.issue.class < ApplicationRecord
                                    xml.a(:href => "/backend/#{intervention.issue.class.table_name}/#{intervention.issue.to_param}") do
                                      xml.text(intervention.issue.observed_at.l) unless intervention.issue.observed_at.nil?
                                    end
                                  else
                                    xml.text(intervention.issue.observed_at.l) unless intervention.issue.observed_at.nil?
                                  end
                                end
                              end
                              xml.dl do
                                xml.dd('aggregator_properties.description'.t(default: [:'attributes.description', :'labels.description', :'activerecord.models.description', "Description"]))
                                xml.dt({}) do
                                  if intervention.issue.class < ApplicationRecord
                                    xml.a(:href => "/backend/#{intervention.issue.class.table_name}/#{intervention.issue.to_param}") do
                                      xml.text(intervention.issue.description)
                                    end
                                  else
                                    xml.text(intervention.issue.description)
                                  end
                                end
                              end
                              xml.dl do
                                xml.dd('aggregator_properties.picture_path'.t(default: [:'attributes.picture_path', :'labels.picture_path', :'activerecord.models.picture_path', "Picture path"]))
                                xml.dt({}) do
                                  if intervention.issue.class < ApplicationRecord
                                    xml.a(:href => "/backend/#{intervention.issue.class.table_name}/#{intervention.issue.to_param}") do
                                      xml.text(intervention.issue.picture_path)
                                    end
                                  else
                                    xml.text(intervention.issue.picture_path)
                                  end
                                end
                              end
                            end
                          end
                        end
                        if (intervention.prescription)
                          xml.section do
                            xml.h1 do
                              xml.span('aggregator_properties.prescription'.t(default: [:'attributes.prescription', :'labels.prescription', :'activerecord.models.prescription', 'Prescription']))
                              xml.text(' ')
                              xml.em({}) do
                                if intervention.prescription.class < ApplicationRecord
                                  xml.a(:href => "/backend/#{intervention.prescription.class.table_name}/#{intervention.prescription.to_param}") do
                                    xml.text(intervention.prescription.reference_number)
                                  end
                                else
                                  xml.text(intervention.prescription.reference_number)
                                end
                              end
                            end
                            xml.div(:class => 'section-content') do
                              xml.dl do
                                xml.dd('aggregator_properties.name'.t(default: [:'attributes.name', :'labels.name', :'activerecord.models.name', "Name"]))
                                xml.dt({}) do
                                  if intervention.prescription.class < ApplicationRecord
                                    xml.a(:href => "/backend/#{intervention.prescription.class.table_name}/#{intervention.prescription.to_param}") do
                                      xml.text(intervention.prescription.name)
                                    end
                                  else
                                    xml.text(intervention.prescription.name)
                                  end
                                end
                              end
                            end
                          end
                        end
                        xml.table(:class => 'matrix') do
                          xml.thead do
                            xml.tr do
                              xml.th('aggregator_properties.variant_name'.t(default: [:'attributes.variant_name', :'labels.variant_name', :'activerecord.models.variant_name', "Variant name"]), :class => 'variant-name')
                              xml.th('aggregator_properties.quantity'.t(default: [:'attributes.quantity', :'labels.quantity', :'activerecord.models.quantity', "Quantity"]), :class => 'quantity')
                              xml.th(:class => 'matrix withdrawal-periods') do
                                xml.table(:class => 'matrix') do
                                  xml.thead do
                                    xml.tr do
                                      xml.th('aggregator_properties.meat_withdrawal_period'.t(default: [:'attributes.meat_withdrawal_period', :'labels.meat_withdrawal_period', :'activerecord.models.meat_withdrawal_period', "Meat withdrawal period"]), :class => 'meat-withdrawal-period')
                                    end
                                    xml.tr do
                                      xml.th('aggregator_properties.milk_withdrawal_period'.t(default: [:'attributes.milk_withdrawal_period', :'labels.milk_withdrawal_period', :'activerecord.models.milk_withdrawal_period', "Milk withdrawal period"]), :class => 'milk-withdrawal-period')
                                    end
                                  end
                                end
                              end
                              xml.th(:class => 'matrix sale-dates') do
                                xml.table(:class => 'matrix') do
                                  xml.thead do
                                    xml.tr do
                                      xml.th('aggregator_properties.meat_saleable_on'.t(default: [:'attributes.meat_saleable_on', :'labels.meat_saleable_on', :'activerecord.models.meat_saleable_on', "Meat saleable on"]), :class => 'meat-saleable-on')
                                    end
                                    xml.tr do
                                      xml.th('aggregator_properties.milk_saleable_on'.t(default: [:'attributes.milk_saleable_on', :'labels.milk_saleable_on', :'activerecord.models.milk_saleable_on', "Milk saleable on"]), :class => 'milk-saleable-on')
                                    end
                                  end
                                end
                              end
                            end
                          end
                          xml.tbody do
                            for input in intervention.inputs
                              meat_withdrawal_period = input.product.meat_withdrawal_period
                              milk_withdrawal_period = input.product.milk_withdrawal_period
                              xml.tr do
                                xml.td({class: "variant-name"}) do
                                  xml.text(input.product.variant_name)
                                end
                                xml.td({class: "quantity"}) do
                                  xml.text(input.quantity.l.l) unless input.quantity.l.nil?
                                end
                                xml.td(:class => 'matrix withdrawal-periods') do
                                  xml.table(:class => 'matrix') do
                                    xml.tbody do
                                      # No elements
                                      xml.tr do
                                        xml.td({class: "meat-withdrawal-period"}) do
                                          xml.text(meat_withdrawal_period.l) unless meat_withdrawal_period.nil?
                                        end
                                      end
                                      xml.tr do
                                        xml.td({class: "milk-withdrawal-period"}) do
                                          xml.text(milk_withdrawal_period.l) unless milk_withdrawal_period.nil?
                                        end
                                      end
                                    end
                                  end
                                end
                                xml.td(:class => 'matrix sale-dates') do
                                  xml.table(:class => 'matrix') do
                                    xml.tbody do
                                      # No elements
                                      xml.tr do
                                        xml.td({class: "meat-saleable-on"}) do
                                          xml.text((intervention.stopped_at + meat_withdrawal_period.to_d.send(meat_withdrawal_period.unit)).to_time.l) unless (intervention.stopped_at + meat_withdrawal_period.to_d.send(meat_withdrawal_period.unit)).to_time.nil?
                                        end
                                      end
                                      xml.tr do
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
      return __doc__.to_html.html_safe
    end
  end
end
