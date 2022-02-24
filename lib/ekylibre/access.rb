module Ekylibre
  module Access
    # autoload :Resource, 'ekylibre/access/resource'
    autoload :Right, 'ekylibre/access/right'

    class << self
      def config_file
        Rails.root.join('config', 'rights.yml')
      end

      # Load a right definition file
      def load_file(file, origin = :unknown)
        YAML.load_file(file).each do |category, resources|
          resources.each do |resource, interactions|
            interactions.each do |interaction, options|
              add_right(category, resource, interaction, options.symbolize_keys.merge(origin: origin))
            end
          end
        end
      end

      def resources
        @resources.deep_symbolize_keys
      end

      # Add an access right
      def add_right(category, resource, interaction, options = {})
        right = Right.new(category, resource, interaction, options)
        # @rights << right unless @rights.include?(right)
        @resources ||= {}.with_indifferent_access
        @resources[right.category] ||= {}.with_indifferent_access
        @resources[right.category][right.resource] ||= {}.with_indifferent_access
        @resources[right.category][right.resource][right.interaction] = right
      end

      # Remove an access right
      def remove_right(category, resource, interaction)
        right = find(category, resource, interaction)
        # @rights.delete(right)
        @resources[category][resource].delete(right)
      end

      # Find a given right by resource and interaction
      def find(category, resource, interaction)
        return @resources[category][resource][interaction] if @resources[category] && @resources[category][resource]

        nil
      end

      # Returns the translated name of a category
      def human_category_name(category)
        "access.categories.#{category}".t
      end

      # Returns the translated name of a resource
      def human_resource_name(resource)
        "access.resources.#{resource}".t
      end

      # Returns the translated name of an interaction (with a resource)
      def human_interaction_name(interaction)
        "access.interactions.#{interaction}".t
      end

      # Returns list of interactions
      def interactions
        @resources.collect do |_name, interactions|
          interactions.keys
        end.flatten.uniq.sort.map(&:to_sym)
      end

      # Returns interactions of a given resource
      def interactions_of(resource)
        @resources[resource].keys
      end

      # Returns a hash for all known rights
      def all_rights
        @resources.each_with_object({}) do |pair, hash|
          hash[pair.first.to_s] = pair.second.keys.map(&:to_s)
          hash
        end
      end

      def rights_of(action)
        list = []
        @resources.each do |_category, resources|
          resources.each do |_resource, interactions|
            interactions.each do |_interaction, right|
              list << right.name if right.actions.include?(action)
            end
          end
        end
        list
      end
    end

    load_file(config_file, :ekylibre)
  end
end
