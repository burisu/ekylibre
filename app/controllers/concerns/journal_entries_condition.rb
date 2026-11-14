# frozen_string_literal: true

module JournalEntriesCondition
  extend ActiveSupport::Concern

  module ClassMethods
    # Returns a list condition Proc filtering journal entries
    def journal_entries_conditions(options = {})
      filter = { JournalEntryItem.table_name => %i[name debit credit] }
      search_options = {}
      unless options[:with_items]
        items_search = search_conditions(filter.dup)
        search_options[:filters] = {
          -> { "#{JournalEntry.table_name}.id IN (SELECT entry_id FROM #{JournalEntryItem.table_name} WHERE #{instance_exec(&items_search)[0]})" } =>
            -> { instance_exec(&items_search)[1..] }
        }
        filter.delete(JournalEntryItem.table_name)
      end
      filter[JournalEntry.table_name] = %i[number debit credit]
      search = search_conditions(filter, search_options)
      journals = journals_crit('params') if options[:with_journals]
      states = journal_entries_states_crit('params') unless options[:state]
      period = journal_period_crit('params')
      state = options[:state]&.to_s

      lambda do
        c = instance_exec(&search)
        if journals
          instance_exec(c, &journals)
        else
          c[0] += " AND (#{JournalEntry.table_name}.journal_id=?)"
          c << params[:id]
        end
        if state
          c[0] += " AND (#{JournalEntry.table_name}.state=?)"
          c << state
        else
          instance_exec(c, &states)
        end
        instance_exec(c, &period)
        c
      end
    end
  end
end
