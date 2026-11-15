# frozen_string_literal: true

# Reads bank statements of OFX files: OFX 1.x (SGML, with unclosed leaf
# elements) and OFX 2.x (XML).
#
#   ofx = OfxParser.parse(content)
#   account = ofx.bank_accounts.first
#   account.number, account.routing_number, account.branch_number
#   account.statement.currency, .start_date, .end_date, .transactions
#   transaction.payee, .memo, .fit_id, .date, .date_initiated, .amount
module OfxParser
  class InvalidFile < StandardError; end

  Document = Struct.new(:bank_accounts)
  BankAccount = Struct.new(:number, :routing_number, :branch_number, :type, :statement)
  Statement = Struct.new(:currency, :start_date, :end_date, :transactions)
  Transaction = Struct.new(:type, :payee, :memo, :fit_id, :check_number, :date, :date_initiated, :amount)

  class << self
    def parse(content)
      body = content.to_s[/<OFX>.*<\/OFX>/mi]
      raise InvalidFile.new('No OFX element found') unless body

      xml = Nokogiri::XML(close_leaf_elements(body), &:strict)
      Document.new(xml.xpath('//STMTRS').map { |statement| bank_account(statement) })
    rescue Nokogiri::XML::SyntaxError => e
      raise InvalidFile.new("Invalid OFX: #{e.message}")
    end

    private

      # OFX 1.x elements holding a value are not closed (<CODE>0): closes
      # them and escapes their values so the document is valid XML.
      def close_leaf_elements(body)
        tokens = body.scan(/<(\/?)([A-Za-z0-9.]+)>([^<]*)/)
        xml = +''
        tokens.each_with_index do |(closing, name, text), index|
          if closing.present?
            xml << "</#{name}>"
          elsif text.strip.empty?
            xml << "<#{name}>"
          else
            xml << "<#{name}>#{CGI.escapeHTML(text.strip)}"
            next_token = tokens[index + 1]
            xml << "</#{name}>" unless next_token && next_token[0].present? && next_token[1] == name
          end
        end
        xml
      end

      def bank_account(statement)
        account = statement.at_xpath('BANKACCTFROM')
        BankAccount.new(
          value(account, 'ACCTID'), value(account, 'BANKID'), value(account, 'BRANCHID'), value(account, 'ACCTTYPE'),
          Statement.new(
            value(statement, 'CURDEF'),
            date(value(statement, 'BANKTRANLIST/DTSTART')),
            date(value(statement, 'BANKTRANLIST/DTEND')),
            statement.xpath('BANKTRANLIST/STMTTRN').map { |transaction| transaction(transaction) }
          )
        )
      end

      def transaction(element)
        Transaction.new(
          value(element, 'TRNTYPE'),
          value(element, 'NAME') || value(element, 'PAYEE/NAME'),
          value(element, 'MEMO'),
          value(element, 'FITID'),
          value(element, 'CHECKNUM'),
          date(value(element, 'DTPOSTED')),
          date(value(element, 'DTUSER')),
          value(element, 'TRNAMT')&.tr(',', '.')&.to_d
        )
      end

      def value(element, path)
        element&.at_xpath(path)&.text&.strip.presence
      end

      # OFX dates: YYYYMMDD[HHMMSS[.XXX]][[gmt offset:tz name]]
      def date(text)
        Date.strptime(text[0, 8], '%Y%m%d') if text
      end
  end
end
