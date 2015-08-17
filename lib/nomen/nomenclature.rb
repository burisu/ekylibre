module Nomen
  # This class represents a nomenclature
  class Nomenclature
    attr_reader :properties, :items, :name, :roots
    attr_accessor :name, :notions, :translateable, :forest_right
    alias_method :property_natures, :properties

    # Instanciate a new nomenclature
    def initialize(name, options = {})
      @name = name.to_sym
      @set = options.delete(:set)
      @items = HashWithIndifferentAccess.new
      @forest_right = 0
      @roots = []
      @properties = {}.with_indifferent_access
      @translateable = !options[:translateable].is_a?(FalseClass)
      @notions = options[:notions] || []
    end

    class << self
      def harvest(element, options = {})
        notions = element.attr('notions').to_s.split(/\s*\,\s*/).map(&:to_sym)
        options[:notions] = notions if notions.any?
        options[:translateable] = !(element.attr('translateable').to_s == 'false')
        name = element.attr('name').to_s
        nomenclature = new(name, options)
        for property in element.xpath('xmlns:properties/xmlns:property')
          nomenclature.harvest_property(property)
        end
        for item in element.xpath('xmlns:items/xmlns:item')
          nomenclature.harvest_item(item)
        end
        nomenclature.rebuild_tree!
        nomenclature
      end
    end

    # def roots
    #   @items.values.select(&:root?)
    # end

    def name=(value)
      @name = value.to_sym
    end

    def update_attributes(attributes = {})
      attributes.each do |attribute, value|
        send("#{attribute}=", value)
      end
    end

    def references
      unless @references
        @references = []
        properties.each do |_p, property|
          if property.item_reference?
            @references << Nomen::Reference.new(@set, property, @set.find(property.source), property.item_list? ? :array : :key)
          end
        end
      end
      @references
    end

    def to_xml_attrs
      attrs = { name: name, translateable: translateable.to_s }
      attrs[:notions] = @notions.join(', ') if @notions.any?
      attrs
    end

    # Build a nested set index on items
    # Returns last right value
    def rebuild_tree!
      @forest_right = 0
      roots.each(&:rebuild_tree!)
    end

    # Add an item to the nomenclature from an XML element
    def harvest_item(element, options = {})
      name = element.attr('name').to_s
      parent = options[:parent] || (element.key?('parent') ? element['parent'] : nil)
      options = element.attributes.each_with_object(HashWithIndifferentAccess.new) do |(k, v), h|
        next if %w(name parent).include?(k)
        h[k] = cast_property(k, v.to_s)
      end
      options[:parent] = parent if parent
      item = add_item(name, options, rebuild: false)
      item
    end

    # Add an property to the nomenclature from an XML element
    def harvest_property(element)
      name = element.attr('name').to_sym
      type = element.attr('type').to_sym
      options = {}
      if element.has_attribute?('fallbacks')
        options[:fallbacks] = element.attr('fallbacks').to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
      end
      if element.has_attribute?('default')
        options[:default] = element.attr('default').to_sym
      end
      options[:required] = !!(element.attr('required').to_s == 'true')
      # options[:inherit]  = !!(element.attr('inherit').to_s == 'true')
      if type == :list
        type = element.has_attribute?('nomenclature') ? :item_list : :choice_list
      elsif type == :choice
        type = :item if element.has_attribute?('nomenclature')
      end
      if type == :choice || type == :choice_list
        if element.has_attribute?('choices')
          options[:choices] = element.attr('choices').to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
        else
          type = :string_list
        end
      elsif type == :item || type == :item_list
        if element.has_attribute?('choices')
          options[:choices] = element.attr('choices').to_s.strip.to_sym
        elsif element.has_attribute?('nomenclature')
          options[:choices] = element.attr('nomenclature').to_s.strip.to_sym
        else
          fail MissingChoices, "[#{@name}] Property #{name} must have nomenclature as choices"
        end
      end
      unless Nomen::PROPERTY_TYPES.include?(type)
        fail ArgumentError, "Property #{name} type is unknown: #{type.inspect}"
      end
      add_property(name, type, options)
    end

    # Add an item to the nomenclature
    def add_item(name, attributes = {}, options = {})
      i = Item.new(self, name, attributes)
      if @items[i.name]
        fail "Item #{i.name} is already defined in nomenclature #{@name}"
      end
      @items[i.name] = i
      @roots << i unless i.parent?
      i.rebuild_tree! unless options[:rebuild].is_a?(FalseClass)
      i
    end

    # Add an item to the nomenclature
    def change_item(name, changes = {})
      i = find!(name)
      has_parent = changes.key?(:parent)
      new_parent = changes.delete(:parent)
      new_name = changes.delete(:name)
      changes.each do |k, v|
        i.set(k, v)
      end
      if has_parent
        @roots << i if i.parent? && new_parent.nil?
        @roots.delete(i) if i.root? && new_parent
        i.parent = new_parent
      end
      i = rename_item(name, new_name) if new_name
      i
    end

    def rename_item(name, new_name)
      if @items[new_name]
        fail "Item #{new_name} is already defined in nomenclature #{@name}. Use merging instead."
      end
      i = find!(name)
      i.children.each do |child|
        child.parent_name = new_name
      end
      cascade_item_renaming(name.to_sym, new_name.to_sym)
      i = @items.delete(i.name)
      i.name = new_name
      @items[new_name] = i
      i
    end

    # name and new_name are Symbol
    def cascade_item_renaming(name, new_name)
      @set.references.each do |reference|
        if reference.foreign_nomenclature == self
          p = reference.property
          if p.list?
            reference.nomenclature.find_each do |item|
              v = item.property(p.name)
              if v && v.include?(name)
                l = v.map do |n|
                  n == name ? new_name : n
                end
                item.set(p.name, l)
              end
            end
          else
            reference.nomenclature.find_each do |item|
              v = item.property(p.name)
              item.set(p.name, new_name) if v == name
            end
          end
        end
      end
    end

    def merge_item(name, into)
      i = find!(name)
      dest = find!(into)
      i.children.each do |child|
        child.parent = dest
      end
      cascade_item_renaming(name.to_sym, into.to_sym)
      @items.delete(name)
    end

    # Add an property to the nomenclature
    def add_property(name, type, options = {})
      p = PropertyNature.new(self, name, type, options)
      if @properties[p.name]
        fail "Property #{p.name} is already defined in nomenclature #{@name}"
      end
      @properties[p.name] = p
      @references = nil
      p
    end

    def sibling(name)
      @set.find(name)
    end

    def check!
      # Check properties
      for property in @properties.values
        if property.choices_nomenclature && !property.inline_choices? && !Nomen[property.choices_nomenclature.to_s]
          fail InvalidPropertyNature, "[#{name}] #{property.name} nomenclature property must refer to an existing nomenclature. Got #{property.choices_nomenclature.inspect}. Expecting: #{Nomen.names.inspect}"
        end
        if property.type == :choice && property.default
          unless property.choices.include?(property.default)
            fail InvalidPropertyNature, "The default choice #{property.default.inspect} is invalid (in #{name}##{property.name}). Pick one from #{property.choices.sort.inspect}."
          end
        end
      end

      # Check items
      for item in list
        for property in @properties.values
          choices = property.choices
          if item.property(property.name) && property.type == :choice
            # Cleans for parametric reference
            name = item.property(property.name).to_s.split(/\(/).first.to_sym
            unless choices.include?(name)
              fail InvalidProperty, "The given choice #{name.inspect} is invalid (in #{self.name}##{item.name}). Pick one from #{choices.sort.inspect}."
            end
          elsif item.property(property.name) && property.type == :list && property.choices_nomenclature
            for name in item.property(property.name) || []
              # Cleans for parametric reference
              name = name.to_s.split(/\(/).first.to_sym
              unless choices.include?(name)
                fail InvalidProperty, "The given choice #{name.inspect} is invalid (in #{self.name}##{item.name}). Pick one from #{choices.sort.inspect}."
              end
            end
          end
        end
      end

      # Default return
      true
    end

    def inspect
      "Nomen::#{name.to_s.classify}"
    end

    # Returns hash with items in tree: {a => nil, b => {c => nil}}
    def tree
      x = @roots.collect(&:tree).join
      return x
      i.attributes.merge(parent: i.parent_name, name: i.name, left: i.left, right: i.right, depth: i.depth).deep_stringify_keys
      return x
      @roots.map do |_i|
      end
    end

    def translateable?
      @translateable
    end

    # Return human name
    def human_name(options = {})
      "nomenclatures.#{name}.name".t(options.merge(default: ["labels.#{name}".to_sym, name.to_s.humanize]))
    end
    alias_method :humanize, :human_name

    def new_boundaries(count = 2)
      boundaries = []
      count.times do
        @forest_right += 1
        boundaries << @forest_right
      end
      boundaries
    end

    # Returns the given item
    def [](item_name)
      @items[item_name]
    end

    # List all item names. Can filter on a given item name and its children
    def to_a(item_name = nil)
      if item_name.present? && @items[item_name]
        return @items[item_name].self_and_children.map(&:name)
      else
        return @items.keys.sort
      end
    end
    alias_method :all, :to_a

    def <=>(other)
      name <=> other.name
    end

    def dependency_index
      unless @dependency_index
        @dependency_index = 0
        properties.each do |_n, p|
          if p.choices_nomenclature && !p.inline_choices?
            @dependency_index += 1 + Nomen[p.choices_nomenclature].dependency_index
          end
        end
      end
      @dependency_index
    end

    # Returns a list for select as an array of pair (array)
    def selection(item_name = nil)
      items = (item_name ? @items[item_name].self_and_children : @items.values)
      items.collect do |item|
        [item.human_name, item.name.to_s]
      end.sort do |a, b|
        a.first.lower_ascii <=> b.first.lower_ascii
      end
    end

    # Returns a list for select as an array of pair (hash)
    def selection_hash(item_name = nil)
      @items[item_name].self_and_children.map do |item|
        { label: item.human_name, value: item.name }
      end.sort { |a, b| a[:label].lower_ascii <=> b[:label].lower_ascii }
    end

    # Returns a list for select, without specified items
    def select_without(already_imported)
      selection = @items.values.collect do |item|
        [item.human_name, item.name.to_s] unless already_imported[item.name.to_s]
      end
      selection.compact!
      selection.sort! do |a, b|
        a.first <=> b.first
      end
      selection
    end

    # Return first item name
    def first(item_name = nil)
      all(item_name).first
    end

    # Return the default item name
    def default(item_name = nil)
      first(item_name)
    end

    # Return the Item for the given name
    def find(item_name)
      @items[item_name]
    end
    alias_method :item, :find

    def property(property_name)
      @properties[property_name]
    end

    def find!(item_name)
      unless i = @items[item_name]
        fail "Cannot find item #{item_name} in #{name}"
      end
      i
    end

    # Returns list of items as an Array
    def list
      @items.values
    end

    # Iterates on items
    def find_each(&block)
      list.each(&block)
    end

    # List items with properties filtering
    def where(properties)
      @items.values.select do |item|
        valid = true
        for name, value in properties
          item_value = item.property(name)
          if value.is_a?(Array)
            one_found = false
            for val in value
              if val.is_a?(Nomen::Item)
                one_found = true if item_value == val.name.to_sym
              else
                one_found = true if item_value == val
              end
            end
            valid = false unless one_found
          elsif value.is_a?(Nomen::Item)
            valid = false unless item_value == value.name.to_sym
          else
            valid = false unless item_value == value
          end
        end
        valid
      end
    end

    def find_by(properties)
      items = where(properties)
      return nil unless items.any?
      items.first
    end

    # Returns the best match on nomenclature properties
    def best_match(property_name, searched_item)
      items = []
      begin
        list.select do |item|
          items << item if item.property(property_name) == searched_item.name
        end
        break if items.any?
        searched_item = searched_item.parent
      end while searched_item
      items
    end

    # Returns property nature
    def method_missing(method_name, *args)
      @properties[method_name] || super
    end

    def cast_property(name, value)
      value = value.to_s
      if property = properties[name]
        if property.type == :choice || property.type == :item
          if value =~ /\,/
            fail InvalidPropertyNature, 'A property nature of choice type cannot contain commas'
          end
          value = value.strip.to_sym
        elsif property.list?
          value = value.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
        elsif property.type == :boolean
          value = (value == 'true' ? true : value == 'false' ? false : nil)
        elsif property.type == :decimal
          value = value.to_d
        elsif property.type == :integer
          value = value.to_i
        elsif property.type == :symbol
          unless value =~ /\A\w+\z/
            fail InvalidPropertyNature, "A property '#{name}' must contains a symbol. /[a-z0-9_]/ accepted. No spaces. Got #{value.inspect}"
          end
          value = value.to_sym
        end
      elsif !%w(name parent aliases).include?(name.to_s)
        fail ArgumentError, "Undefined property '#{name}' in #{@name}"
      end
      value
    end
  end
end
