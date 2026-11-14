module Onoma
  module Migration
    module Actions
      class PropertyChange < Onoma::Migration::Actions::Base
        attr_reader :nomenclature, :name, :changes
        def initialize(element)
          name = element['property'].split('.')
          @nomenclature = name.first
          @name = name.second

          @changes = {}
          if element.has_attribute?('type')
            changes[:type] = element.attr('type').to_sym
          end
          if element.has_attribute?('fallbacks')
            @changes[:fallbacks] = element.attr('fallbacks').to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
          end
          if element.has_attribute?('default')
            @changes[:default] = element.attr('default').to_sym
          end
          if element.has_attribute?('required')
            @changes[:required] = element.attr('required').to_s == 'true'
          end
          # @changes[:inherit]  = !!(element.attr('inherit').to_s == 'true')
          if element.has_attribute?('choices')
            if type == :choice || type == :choice_list
              @changes[:choices] = element.attr('choices').to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
            elsif type == :item || type == :item_list
              @changes[:choices] = element.attr('choices').to_s.strip.to_sym
            end
          end
        end
      end
    end
  end
end
