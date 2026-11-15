# frozen_string_literal: true

module Ekylibre
  # Status of long administration tasks (tenant creation, dumps, restores,
  # lexicon loading...) shared between the web, job and rake processes.
  # Stored in Solid Cache (its own database), in memory in tests.
  module TaskStatus
    class << self
      attr_writer :store

      def store
        @store ||= if Rails.env.test?
                     ActiveSupport::Cache::MemoryStore.new
                   else
                     ActiveSupport::Cache.lookup_store(:solid_cache_store, namespace: 'task_status')
                   end
      end

      # Returns the status fields (string keys), empty if unknown
      def read(key)
        store.read(key) || {}
      end

      # Sets the given fields, keeping the others
      def update(key, **fields)
        store.write(key, read(key).merge(fields.transform_keys(&:to_s).transform_values { |v| v&.to_s }))
      end

      def delete(key)
        store.delete(key)
      end
    end
  end
end
