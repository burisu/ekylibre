# frozen_string_literal: true

# Rails 5.2 typed the sum of an SQL expression with the type of the result
# column, so `items.sum('real_debit - real_credit')` gave BigDecimal 0.0 on an
# empty set. Rails 6.1+ uses a generic type and gives Integer 0, which is shown
# as "0 €" instead of "0,00 €" and makes later divisions integer ones.
# The SQL expressions summed in the app are all amounts: empty sums stay
# decimal.
module EmptySumAsDecimal
  private

    def type_cast_calculated_value(value, operation, type)
      if operation == 'sum' && value.nil? && type.instance_of?(ActiveModel::Type::Value)
        BigDecimal(0)
      else
        super
      end
    end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.prepend(EmptySumAsDecimal)
end
