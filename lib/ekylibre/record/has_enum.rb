# frozen_string_literal: true

module Ekylibre
  module Record
    # Enumerated string attributes.
    #
    # ActiveRecord models use Rails enums (stored values are the strings
    # themselves, validated, without generated scopes or bang methods). On top
    # of them, the reader returns an Enum value that knows how to translate
    # itself (+text+) and answers value predicates (+state.draft?+), and the
    # class exposes the enumeration (+Sale.state.values+, +options+...).
    #
    # Translations are looked up in +i18n_scope+ when given, else in
    # enumerize.<model>.<attribute>.<value>, enumerize.defaults.<attribute>.<value>
    # and enumerize.<attribute>.<value>.
    module HasEnum
      # A value of an enumerated attribute
      class Value < String
        attr_reader :attribute

        def initialize(attribute, value)
          super(value.to_s)
          @attribute = attribute
          freeze
        end

        def value
          to_s
        end

        # Compares with strings and symbols (state == :draft)
        def ==(other)
          other.is_a?(Symbol) ? to_s == other.to_s : super
        end

        def text
          attribute.human_value_name(self)
        end
        alias l text
        alias human_name text

        def encode_with(coder)
          coder.represent_scalar(nil, to_s)
        end

        def respond_to_missing?(name, include_private = false)
          value_predicate?(name) || super
        end

        def method_missing(name, *args)
          return super unless value_predicate?(name)

          self == name.to_s.chomp('?')
        end

        private

          def value_predicate?(name)
            name.end_with?('?') && attribute.value?(name.to_s.chomp('?'))
          end
      end

      # The definition of an enumerated attribute
      class Attribute
        attr_reader :klass, :name, :default

        def initialize(klass, name, values, default: nil, i18n_scope: nil)
          @klass = klass
          @name = name.to_s
          @raw_values = values
          @default = default
          @i18n_scopes = Array(i18n_scope).map(&:to_s)
        end

        def values
          @values ||= @raw_values.map { |value| Value.new(self, value) }.freeze
        end

        def value?(value)
          values.include?(value.to_s)
        end

        def find_value(value)
          return nil if value.nil?

          values.detect { |v| v == value.to_s }
        end

        def default_value
          @default.is_a?(Proc) ? nil : find_value(@default)
        end

        # Values ready to be used in a select: [[text, value], ...]
        def options(only: nil, except: nil)
          selected = values
          selected = selected.select { |v| Array(only).map(&:to_s).include?(v) } if only
          selected = selected.reject { |v| Array(except).map(&:to_s).include?(v) } if except
          selected.map { |value| [value.text, value.to_s] }
        end

        # Values are reachable by name: Sale.state.draft
        def respond_to_missing?(name, include_private = false)
          value?(name) || super
        end

        def method_missing(name, *args)
          value?(name) && args.empty? ? find_value(name) : super
        end

        def human_value_name(value)
          keys = if @i18n_scopes.any?
                   @i18n_scopes.map { |scope| :"#{scope}.#{value}" }
                 else
                   [:"enumerize.#{klass.model_name.i18n_key}.#{name}.#{value}",
                    :"enumerize.defaults.#{name}.#{value}",
                    :"enumerize.#{name}.#{value}"]
                 end
          ::I18n.t(keys.first, default: [*keys[1..], value.to_s.humanize])
        end
      end

      def self.extended(base)
        base.class_attribute :enum_attributes, instance_writer: false, default: {}.freeze
      end

      # Declares an enumerated attribute.
      #
      # Options:
      # - in: the values (symbols or strings)
      # - default: value (or Proc evaluated on new records)
      # - predicates: true defines <value>? methods, { prefix: true } defines <attr>_<value>?
      # - scope: true defines with_<attr>(*values) and without_<attr>(*values) scopes
      # - i18n_scope: scope(s) where to find the translations of values
      # - validate: false skips the inclusion validation
      def has_enum(name, **options)
        name = name.to_s
        values = Array(options.fetch(:in)).map(&:to_s).uniq
        default = options[:default]
        attribute = Attribute.new(self, name, values, default: default, i18n_scope: options[:i18n_scope])
        self.enum_attributes = enum_attributes.merge(name => attribute).freeze

        # Rails enums cannot be empty (lists computed at load time may be)
        rails_enum = self < ActiveRecord::Base && options.fetch(:rails_enum, true) && values.any?
        if rails_enum
          enum name, values.index_with(&:itself), validate: (options[:validate] == false ? nil : { allow_nil: true }),
                                                  scopes: false, instance_methods: false
        elsif options[:validate] != false
          validates name, inclusion: { in: values }, allow_blank: true
        end

        # Defaults apply to records whose value is nil after initialization
        # (persisted ones too, like enumerize did)
        if !default.nil? && respond_to?(:after_initialize)
          after_initialize do
            if has_attribute?(name) && self[name].nil?
              self[name] = default.is_a?(Proc) ? instance_exec(&default) : default.to_s
            end
          end
        end

        define_enum_methods(attribute, options)
        attribute
      end

      # Kept for compatibility with enumerize declarations
      def enumerized_attributes
        enum_attributes.with_indifferent_access
      end

      private

        def enum_methods_module
          @enum_methods_module ||= Module.new.tap { |mod| include mod }
        end

        def define_enum_methods(attribute, options)
          name = attribute.name
          enum_methods_module.module_eval do
            define_method(name) do
              # Unknown (or blank) stored values read as nil, like enumerize did
              attribute.find_value(super())
            end

            define_method("#{name}_text") do
              value = public_send(name)
              value.respond_to?(:text) ? value.text : value
            end
          end

          # Model.<attribute> gives the definition, unless it would hide a
          # framework class method (like Class#name)
          define_singleton_method(name) { attribute } unless ActiveRecord::Base.respond_to?(name)

          if (predicates = options[:predicates])
            prefix = predicates.is_a?(Hash) && predicates[:prefix] ? "#{name}_" : ''
            attribute.values.each do |value|
              method_name = "#{prefix}#{value}?"
              # Existing methods win (like with enumerize)
              next if method_defined?(method_name)

              define_method(method_name) { self[name].to_s == value }
            end
          end

          return unless options[:scope]

          scope :"with_#{name}", ->(*values) { where(name => values.flatten.map(&:to_s)) }
          scope :"without_#{name}", ->(*values) { where.not(name => values.flatten.map(&:to_s)) }
        end
    end
  end
end
