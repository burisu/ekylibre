# frozen_string_literal: true

require 'rodf'

module ActiveList
  # Builds export files (CSV, Excel CSV, ODS) from a list definition
  class Exporters
    FILE_EXTENSIONS = { csv: 'csv', xcsv: 'csv', ods: 'ods' }.freeze

    attr_reader :table, :context, :state

    def initialize(table, context, options = {})
      @table = table
      @context = context
      @state = State.new(table, context, options)
    end

    def file_name
      table.model.model_name.human
    end

    def mime_type(format)
      Mime[format].to_s
    end

    def file_extension(format)
      FILE_EXTENSIONS.fetch(format.to_sym)
    end

    def records
      Query.new(table, context, state).records(paginate: false)
    end

    def headers
      table.exportable_columns.map { |column| column.header(context).to_s }
    end

    def row(record)
      table.exportable_columns.map { |column| column.exporting_datum(context, record) }
    end

    def generate(format)
      case format.to_sym
      when :csv then to_csv
      when :xcsv then to_csv(col_sep: ';', encoding: 'CP1252')
      when :ods then to_ods
      else raise ArgumentError.new("Unknown export format: #{format}")
      end
    end

    def to_csv(col_sep: ',', encoding: nil)
      encode = ->(v) { encoding ? v.to_s.encode(encoding, invalid: :replace, undef: :replace) : v }
      ::CSV.generate(col_sep: col_sep) do |csv|
        csv << headers.map(&encode)
        records.each { |record| csv << row(record).map(&encode) }
      end
    end

    def to_ods
      exporter = self
      title = file_name
      spreadsheet = RODF::Spreadsheet.new
      spreadsheet.office_style :head, family: :cell do
        property :text, 'font-weight': :bold
        property :paragraph, 'text-align': :center
      end
      spreadsheet.table title do
        row do
          exporter.headers.each { |header| cell header, style: :head }
        end
        exporter.records.each do |record|
          values = exporter.row(record)
          row do
            values.each { |value| cell value }
          end
        end
      end
      spreadsheet.bytes
    end
  end
end
