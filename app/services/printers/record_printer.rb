# frozen_string_literal: true

module Printers
  # Generic printer exposing a record (or a collection of records) to a
  # Liquid template, serialized like the former Jasper XML datasource
  # (`serializable_hash` with the same methods/include options).
  #
  # Template data:
  # - s0: the record attributes, or s0.records for a collection
  # - s0.company: the company entity
  # - s0.printed_at
  class RecordPrinter < PrinterBase
    attr_reader :record, :serialization

    def initialize(template:, record:, key: nil, name: nil, serialization: {})
      super(template: template)
      @record = record
      @key = key
      @name = name
      @serialization = serialization
    end

    def key
      @key || (record.respond_to?(:number) ? record.number : record.try(:id)).to_s
    end

    def document_name
      @name || super
    end

    def generate(report)
      dataset.each { |name, value| report.add_field(name, value) }
    end

    def dataset
      data = if record.is_a?(ActiveRecord::Base)
               serialize(record)
             elsif record.respond_to?(:to_a)
               { 'records' => record.to_a.map { |item| serialize(item) } }
             else
               {}
             end
      company = Entity.of_company
      data.merge(
        'company' => company ? serialize_company(company) : {},
        'printed_at' => Time.zone.now.l
      )
    end

    private

      def serialize(item)
        localize(item.serializable_hash(serialization.deep_dup))
      end

      def serialize_company(company)
        hash = company.serializable_hash(methods: %i[full_name siret_number vat_number activity_code])
        hash['address'] = company.default_mail_address&.coordinate
        hash['picture_path'] = company.picture_path if company.respond_to?(:has_picture?) && company.has_picture?
        localize(hash)
      end

      # Dates and numbers are localized as Jasper templates did
      def localize(value)
        case value
        when Hash then value.transform_values { |v| localize(v) }
        when Array then value.map { |v| localize(v) }
        when Date, Time, DateTime, ActiveSupport::TimeWithZone, BigDecimal, Float
          value.respond_to?(:l) ? value.l : value
        else value
        end
      end
  end
end
