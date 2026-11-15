module Onoma
  module Migration
    module Actions
      class NomenclatureRemoval < Onoma::Migration::Actions::Base
        attr_reader :nomenclature

        def initialize(element)
          @nomenclature = element['nomenclature']
          raise 'No given nomenclature' if @nomenclature.blank?
        end

        alias name nomenclature

        def human_name
          "Remove nomenclature #{@name}"
        end
      end
    end
  end
end
