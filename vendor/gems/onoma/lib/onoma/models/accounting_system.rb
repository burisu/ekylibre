module Onoma
  class AccountingSystem < Onoma::Record::Base
    class << self
      def with_fiscal_position
        Onoma::FiscalPosition.items.values
            .reduce(Set.new) {|acc, fp| acc << fp.accounting_system}
            .map {|e| Onoma::AccountingSystem[e]}
            .compact
      end
    end
  end
end
