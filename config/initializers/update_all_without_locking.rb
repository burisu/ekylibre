# frozen_string_literal: true

# Since Rails 6.0, Relation#update_all increments the optimistic locking
# column. Ekylibre uses update_all as a silent update in many callbacks
# (bookkeeping, sums, states...) while the record is still in memory, so the
# next save of that record raised ActiveRecord::StaleObjectError.
# This keeps the Rails 5.2 behaviour: update_all does not touch lock_version
# unless it is given explicitly.
module UpdateAllWithoutLocking
  def update_all(updates)
    if klass.locking_enabled? && updates.is_a?(Hash)
      column = klass.locking_column
      unless updates.key?(column) || updates.key?(column.to_sym)
        updates = updates.merge(column => Arel.sql(klass.connection.quote_column_name(column)))
      end
    end
    super(updates)
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.prepend(UpdateAllWithoutLocking)
end
