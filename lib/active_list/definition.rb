# frozen_string_literal: true

module ActiveList
  module Definition
    LABELS_COLUMNS = %i[full_name label name number coordinate].freeze

    class AbstractColumn
      attr_reader :table, :name, :id, :options, :condition

      def initialize(table, name, options = {})
        @table = table
        @name = name.to_sym
        @options = options
        @hidden = !!@options.delete(:hidden)
        @condition = @options.delete(:condition)
        @id = 'c' + @table.new_column_id
      end

      def hidden?
        @hidden
      end

      def sortable?
        false
      end

      def exportable?
        false
      end

      def computable?
        false
      end

      def data?
        false
      end

      def unique_id
        "#{@table.name}-#{@name}"
      end

      def short_id
        @id
      end

      def sort_id
        name
      end

      def header(_context)
        ''
      end
    end

    class DataColumn < AbstractColumn
      def data?
        true
      end

      def header(_context)
        if @options[:label]
          @options[:label].to_s.strip.t(scope: 'labels')
        else
          @table.model.human_attribute_name(@name)
        end
      end

      def datatype
        @options[:datatype] || @column&.type
      end

      def enumerize?
        false
      end

      def numeric?
        %i[decimal integer float numeric].include?(datatype)
      end

      def exportable?
        true
      end

      def sortable?
        true
      end

      # Record holding the attribute (itself or associated record)
      def record_of(record)
        record
      end

      # Currency of the cell, nil if none
      def currency_for(context, record)
        currency = options[:currency]
        return nil if currency.nil? || currency.is_a?(FalseClass)

        currency = currency[:body] if currency.is_a?(Hash)
        currency = :currency if currency.is_a?(TrueClass)
        case currency
        when Symbol
          target = record_of(record)
          target&.public_send(currency)
        when Proc
          Evaluation.value(context, currency, record)
        else
          currency
        end
      end

      # Value used in exports
      def exporting_datum(context, record, noview = false)
        datum = datum(record)
        if datatype == :boolean
          datum ? ::I18n.translate('list.export.true_value') : ::I18n.translate('list.export.false_value')
        elsif datatype == :date
          datum.nil? ? '' : datum.l
        elsif datatype == :decimal && !noview
          currency = currency_for(context, record)
          currency || datum.nil? ? datum : datum.l
        elsif @name.to_s =~ /(^|_)currency$/ && datatype == :string
          Onoma::Currency[datum] ? Onoma::Currency[datum].human_name : ''
        elsif @name.to_s =~ /(^|_)country$/ && datatype == :string
          Onoma::Country[datum] ? Onoma::Country[datum].human_name : ''
        elsif @name.to_s =~ /(^|_)language$/ && datatype == :string
          Onoma::Language[datum] ? Onoma::Language[datum].human_name : ''
        elsif enumerize? || datum.respond_to?(:text)
          datum.nil? ? '' : datum.text
        else
          datum
        end
      end
    end

    class AttributeColumn < DataColumn
      attr_reader :column, :value_method, :label_method, :sort_column, :computation_method

      def initialize(table, name, options = {})
        super(table, name, options)
        @label_method = options[:label_method] || @name
        @label_method = @label_method.to_sym unless @label_method.is_a?(Proc)
        @value_method = if options[:value_method].present?
                          options[:value_method].is_a?(Proc) ? options[:value_method] : options[:value_method].to_sym
                        elsif @label_method.is_a?(Proc)
                          @label_method
                        else
                          @label_method.to_s.gsub('human_', '').to_sym
                        end
        @sort_column = compute_sort_column
        @computation_method = options[:on_select]
        @column = @table.model.columns_hash[@label_method.to_s]
      end

      def datum(record)
        @label_method.is_a?(Proc) ? @label_method.call(record) : record.public_send(@label_method)
      end

      def datum_value(record)
        @value_method.is_a?(Proc) ? @value_method.call(record) : record.public_send(@value_method)
      end

      # Controller of the record for URL building
      def default_url_controller(record)
        record.class.name.tableize
      end

      def sortable?
        !sort_column.nil?
      end

      def computable?
        !computation_method.nil?
      end

      def enumerize?
        table.model.respond_to?(:enumerized_attributes) &&
          !table.model.enumerized_attributes[@label_method].nil?
      end

      def sort_expression
        @sort_column
      end

      private

        def compute_sort_column
          selects = @table.options[:select] || {}
          selects_label = selects.find { |_sql, alias_name| alias_name.to_s == @label_method.to_s }&.last
          selects_name = selects.find { |_sql, alias_name| alias_name.to_s == @name.to_s }&.last
          if (selects_label || selects_name) && options[:sort].blank?
            (selects_label || selects_name).to_s
          else
            sort_column = options[:sort]
            sort_column ||= if @table.model.columns_hash[@label_method.to_s]
                              @label_method
                            elsif @table.model.columns_hash[@name.to_s]
                              @name
                            end
            sort_column && "#{@table.model.table_name}.#{sort_column}"
          end
        end
    end

    class StatusColumn < AttributeColumn
      def initialize(table, name, options = {})
        @tooltip_method = options.delete(:tooltip_method)
        super
      end

      def tooltip_title(record)
        if @tooltip_method
          record.public_send(@tooltip_method)
        else
          record.try(:human_status) || record.try(:human_state_name) || datum_value(record).to_s.capitalize
        end
      end
    end

    class AssociationColumn < DataColumn
      attr_reader :label_method, :reflection

      def initialize(table, name, options = {})
        super(table, name, options)
        raise ArgumentError.new('Option :through must be given') unless @options[:through]

        reflection_name = @options.delete(:through).to_sym
        @reflection = @table.model.reflect_on_association(reflection_name)
        raise ArgumentError.new("Reflection #{reflection_name} cannot be found for #{table.model.name}.") unless @reflection
        unless %i[belongs_to has_one].include?(@reflection.macro)
          raise ArgumentError.new("Only belongs_to are usable. Can't handle: #{@reflection.macro} :#{@reflection.name}.")
        end

        klass = @reflection.class_name.safe_constantize
        raise StandardError.new("Given reflection #{reflection_name} seems to be invalid") unless klass

        columns_def = klass.columns_hash.keys.map(&:to_sym)
        @label_method = @options.delete(:label_method)
        unless @label_method
          columns = columns_def + klass.instance_methods.map(&:to_sym)
          @label_method = LABELS_COLUMNS.detect { |m| columns.include?(m) }
          raise ArgumentError.new(":label_method option must be given for association #{name}.") unless @label_method
        end
        @sort_column = @options.delete(:sort)
        @sort_column ||= if !@label_method.is_a?(Proc) && columns_def.include?(@label_method)
                           @label_method
                         else
                           LABELS_COLUMNS.detect { |m| columns_def.include?(m) } || :id
                         end
      end

      def datum(record)
        associated = record.public_send(@reflection.name)
        return nil if associated.nil?

        @label_method.is_a?(Proc) ? @label_method.call(associated) : associated.public_send(@label_method)
      end

      def datum_value(record)
        datum(record)
      end

      def record_of(record)
        record.public_send(@reflection.name)
      end

      def default_url_controller(_record)
        @reflection.class_name.tableize.to_sym
      end

      def class_name
        @reflection.class_name
      end

      def sort_expression
        same_table_reflections = table.reflections.select { |r| r.table_name == @reflection.table_name }
        if same_table_reflections.size > 1 && same_table_reflections.index { |r| r.name == @reflection.name } > 0
          "#{@reflection.name.to_s.pluralize}_#{table.model.table_name}.#{@sort_column}"
        else
          "#{@reflection.klass.table_name}.#{@sort_column}"
        end
      end
    end

    class ActionColumn < AbstractColumn
      ID_PLACEHOLDER = '##IDS##'
      USE_MODES = %i[none single many both].freeze

      attr_reader :use_mode

      def initialize(table, name, options = {})
        super(table, name, options)
        @use_mode = (@options.delete(:on) || :single).to_sym
        raise "Invalid use mode: #{@use_mode.inspect}" unless USE_MODES.include?(@use_mode)

        if @name.to_s == 'destroy'
          @options[:method] = :delete unless @options.key?(:method)
          @options[:confirm] ||= :are_you_sure_you_want_to_delete unless @options.key?(:confirm)
          @options[:if] ||= :destroyable?
        end
        @options[:if] ||= :editable? if @name.to_s == 'edit'
        @options[:confirm] = :are_you_sure if @options[:confirm].is_a?(TrueClass)
        raise ArgumentError.new(':remote option is not supported') if @options[:remote]
      end

      def use_single?
        @use_mode == :single || @use_mode == :both
      end

      def use_many?
        @use_mode == :many || @use_mode == :both
      end

      def use_none?
        @use_mode == :none
      end

      def global?
        use_none? || use_many?
      end

      # URL for global actions (none / many)
      def default_url(context)
        url = Evaluation.deep(context, (@options[:url] || {}).dup)
        url[:controller] ||= (@options[:controller] || table.model.name.tableize)
        url[:action] ||= @name.to_s
        url[:format] = @options[:format] if @options.key?(:format)
        url[:id] ||= ID_PLACEHOLDER if use_many?
        url
      end

      def link_options
        opts = { class: (@options[:icon_name] || @name).to_s }
        opts['data-confirm'] = @options[:confirm].to_s.t(scope: 'labels') if @options[:confirm]
        opts[:method] = @options[:method].to_s.underscore.to_sym if @options[:method]
        opts
      end

      # Renders the action link for a record, nil if not applicable
      def operation(context, record)
        return nil if @options[:if] && !Evaluation.record_value(context, @options[:if], record)
        return nil if @options[:unless] && Evaluation.record_value(context, @options[:unless], record)

        if @options[:actions]
          raise StandardError.new('Only compatible with single actions') unless use_single?

          current = record.public_send(@name)
          @options[:actions].each do |expected, url|
            next unless current == expected

            url = record_url(context, record, url.dup)
            return context.link_to(context.content_tag(:i) + ERB::Util.html_escape(url[:action].t(scope: 'rest.actions')), url, link_options)
          end
          nil
        else
          url = (@options[:url] || {}).dup
          url[:controller] ||= (@options[:controller] || ->(r) { r.class.name.tableize })
          url[:action] ||= @name.to_s
          url = record_url(context, record, url)
          context.link_to(context.content_tag(:i) + ERB::Util.html_escape(' ' + @name.t(scope: 'rest.actions')), url, link_options)
        end
      end

      private

        def record_url(context, record, url)
          url[:id] = ->(r) { r.id } if url[:id].nil? || url[:id] == ID_PLACEHOLDER
          url[:redirect] = -> { params[:redirect] } unless url.key?(:redirect)
          url = Evaluation.deep(context, url, record)
          url[:format] = @options[:format] if @options[:format]
          url.delete_if { |_k, v| v.nil? }
        end
    end

    class FieldColumn < AbstractColumn
      attr_reader :form_name

      def initialize(table, name, options = {})
        super(table, name, options)
        @form_name = options.delete(:form_name)
      end

      def header(_context)
        @table.model.human_attribute_name(@name.to_s)
      end

      def form_name_for(context, record)
        @form_name ? Evaluation.value(context, @form_name, record) : "#{@table.name}[#{record.id}][#{@name}]"
      end
    end

    class CheckBoxColumn < FieldColumn
      attr_reader :form_value

      def initialize(table, name, options = {})
        super(table, name, options)
        @form_value = options.delete(:form_value)
      end
    end

    class TextFieldColumn < FieldColumn
    end

    class EmptyColumn < AbstractColumn
      def header(_context)
        name.to_s.strip.t(scope: 'labels')
      end
    end

    class IconColumn < AbstractColumn
      def visible_for?(context, record)
        @options[:if].nil? || Evaluation.record_value(context, @options[:if], record)
      end
    end

    class Table
      attr_reader :name, :model, :options, :id, :columns, :controller

      def initialize(name, model, options = {})
        @name = name
        @model = model
        @options = options
        @controller = options.delete(:controller)
        @paginate = !(@options[:pagination] == :none || @options[:paginate].is_a?(FalseClass))
        @options[:per_page] = 20 if @options[:per_page].to_i <= 0
        @options[:page] = 1 if @options[:page].to_i <= 0
        @columns = []
        @id = name.to_s
      end

      # Name of the controller action serving the list
      def action_name
        name == controller.controller_name.to_sym ? 'list' : "list_#{name}"
      end

      # Key used for the user preference (kept from the gem for compatibility)
      def preference_key
        "list._#{controller.controller_name}_list_#{name}_tag"
      end

      def uid
        "#{name}-list"
      end

      def collection?
        @options.fetch(:collection) { model.name == controller.controller_name.to_s.classify }
      end

      def new_column_id
        @current_column_id ||= 0
        id = @current_column_id.to_s
        @current_column_id += 1
        id
      end

      def model_columns
        @model.columns_hash.values
      end

      def sortable_columns
        @columns.select(&:sortable?)
      end

      def exportable_columns
        @columns.select(&:exportable?)
      end

      def paginate?
        @paginate
      end

      def global_action_columns
        action_columns.select(&:global?)
      end

      def selectable?
        @options[:selectable] || action_columns.any?(&:use_many?) || data_columns.any?(&:computable?)
      end

      def table_columns
        cols = model_columns.map(&:name)
        @columns.select { |c| c.is_a?(DataColumn) && cols.include?(c.name.to_s) }
      end

      def data_columns
        @columns.select { |c| c.is_a?(DataColumn) }
      end

      def action_columns
        @columns.select { |c| c.is_a?(ActionColumn) }
      end

      def hidden_columns
        data_columns.select(&:hidden?)
      end

      def reflections
        @columns.each_with_object([]) do |column, list|
          next unless column.respond_to?(:reflection)

          list << column.reflection unless list.detect { |r| r.name == column.reflection.name }
        end
      end

      def default_order
        return @options[:order] if @options.key?(:order)

        cols = table_columns
        cols.any? ? cols.first.name.to_sym : { id: :desc }
      end

      def text_field(name, options = {})
        add TextFieldColumn, name, options
      end

      def check_box(name, options = {})
        add CheckBoxColumn, name, options
      end

      def action(name, options = {})
        add ActionColumn, name, options
      end

      def empty(name, options = {})
        add EmptyColumn, name, options
      end

      def icon(name, options = {})
        add IconColumn, name, options
      end

      def column(name, options = {})
        if @model.reflect_on_association(name)
          options[:through] ||= name
          add AssociationColumn, name, options
        elsif options[:through] && @model.reflect_on_association(options[:through])
          options[:label_method] ||= name
          add AssociationColumn, name, options
        else
          add AttributeColumn, name, options
        end
      end

      def status(*args)
        options = args.extract_options!
        name = args.shift || :status
        add StatusColumn, name, options
      end

      def load_default_columns
        model_columns.each do |column|
          reflections = @model.reflect_on_all_associations(:belongs_to).select { |r| r.foreign_key.to_s == column.name.to_s }
          if reflections.size == 1
            reflection = reflections.first
            columns = reflection.klass.columns.collect(&:name)
            column(%i[label name code number].detect { |l| columns.include?(l.to_s) }, through: reflection.name, url: true)
          else
            column(column.name.to_sym)
          end
        end
        true
      end

      private

        def add(klass, name, options = {})
          raise ArgumentError.new("Name of a column must be a Symbol (got #{name.inspect}).") unless name.is_a?(Symbol)
          raise ArgumentError.new("Column name must be unique. #{name.inspect} is already used in #{self.name}") if @columns.detect { |c| c.name == name }

          @columns << klass.new(self, name, options)
        end
    end
  end
end
