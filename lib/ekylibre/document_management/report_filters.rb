# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    # Liquid filters available in reporting templates
    module ReportFilters
      # Items of a table/section named +name+ in +scope+
      def scope(scope, name)
        scope.respond_to?(:collection) ? scope.collection(name) : []
      end
    end
  end
end
