# frozen_string_literal: true

# Relation#update_all as Ekylibre expects it:
# - Since Rails 6.0 it increments the optimistic locking column. Ekylibre
#   uses update_all as a silent update in many callbacks (bookkeeping, sums,
#   states...) while the record is still in memory, so the next save of that
#   record raised ActiveRecord::StaleObjectError. lock_version is kept unless
#   it is given explicitly.
# - Since Rails 8.0 relations with joins are updated with UPDATE ... FROM,
#   which makes the unqualified columns of their conditions ambiguous. They
#   are updated through a subquery on the primary key, as before.
module UpdateAllWithoutLocking
  def update_all(updates)
    if (joins_values.any? || left_outer_joins_values.any?) && klass.primary_key
      return klass.unscoped.where(klass.primary_key => except(:select).select(klass.primary_key)).update_all(updates)
    end

    if klass.locking_enabled? && updates.is_a?(Hash)
      column = klass.locking_column
      unless updates.key?(column) || updates.key?(column.to_sym)
        updates = updates.merge(column => Arel.sql("#{klass.quoted_table_name}.#{klass.connection.quote_column_name(column)}"))
      end
    end
    super(updates)
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.prepend(UpdateAllWithoutLocking)
end
