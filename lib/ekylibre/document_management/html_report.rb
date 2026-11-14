# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    # Collects printer data with the same DSL as the former odf-report gem
    # (add_field, add_column, add_table, add_section, add_image) so printers
    # keep their code. Data is then exposed to Liquid HTML templates as
    # ReportScope objects.
    class HtmlReport
      # Definition of fields and nested collections, evaluated for each item
      class Definition
        attr_reader :fields, :collections, :images

        def initialize
          @fields = {}
          @collections = {}
          @images = {}
        end

        def add_field(name, data_field = nil, &block)
          @fields[HtmlReport.key(name)] = [data_field, block]
        end
        alias add_column add_field
        alias add_text add_field

        def add_image(name, data_field = nil, _options = {}, &block)
          @images[HtmlReport.key(name)] = [data_field, block]
        end

        def add_table(name, collection_field, _options = {}, &block)
          definition = Definition.new
          block&.call(definition)
          @collections[HtmlReport.key(name)] = [collection_field, definition]
        end
        alias add_section add_table

        # Evaluates the definition for an item and returns a data Hash
        def evaluate(item)
          data = {}
          @fields.each { |key, (field, block)| data[key] = HtmlReport.extract(item, field || key, block) }
          @images.each { |key, (field, block)| data[key] = HtmlReport.image_url(HtmlReport.extract(item, field || key, block)) }
          @collections.each do |key, (field, definition)|
            collection = field.is_a?(Symbol) || field.is_a?(String) ? HtmlReport.extract(item, field, nil) : field
            collection = collection.call(item) if collection.is_a?(Proc)
            data[key] = HtmlReport.items(collection).map { |sub_item| definition.evaluate(sub_item) }
          end
          data
        end
      end

      class << self
        def key(name)
          name.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_+|_+\z/, '')
        end

        # Value of a field for an item, like odf-report did
        def extract(item, field, block)
          return block.call(item) if block

          case item
          when Hash then item.key?(field) ? item[field] : item[field.to_s] || item[field.to_sym]
          when nil then nil
          else item.respond_to?(field) ? item.public_send(field) : nil
          end
        end

        # Normalizes a collection: nil/false hide, a single object repeats once
        def items(collection)
          case collection
          when nil, false then []
          when Hash then [collection]
          when Array then collection
          when Enumerable then collection.to_a
          else collection.is_a?(ActiveRecord::Relation) ? collection.to_a : [collection]
          end
        end

        def image_url(path)
          return nil if path.blank?
          return path if path.to_s =~ %r{\A(data|https?|file):}

          "file://#{File.expand_path(path.to_s)}"
        end
      end

      def initialize
        @root = Definition.new
        @values = {}
      end

      def add_field(name, value = nil, &block)
        @values[self.class.key(name)] = block ? block.call : value
      end
      alias add_text add_field

      def add_image(name, path = nil, _options = {}, &block)
        @values[self.class.key(name)] = self.class.image_url(block ? block.call : path)
      end

      def add_table(name, collection, options = {}, &block)
        @root.add_table(name, collection.is_a?(Proc) ? collection : ->(_) { collection }, options, &block)
      end
      alias add_section add_table

      # @return [Hash] document data
      def data
        @values.merge(@root.evaluate(nil))
      end

      # @return [ReportScope]
      def to_scope
        ReportScope.new(data)
      end
    end
  end
end
