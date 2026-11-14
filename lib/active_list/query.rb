# frozen_string_literal: true

module ActiveList
  # Builds the ActiveRecord relation of a list
  class Query
    attr_reader :table, :context, :state, :count, :page, :limit, :offset, :last_page

    def initialize(table, context, state)
      @table = table
      @context = context
      @state = state
    end

    def model
      constant_name = state.options[:constant_name].presence
      if constant_name
        klass = constant_name.to_s.safe_constantize
        return klass if klass && klass <= table.model
      end
      if table.collection? && context.respond_to?(:controller_name)
        klass = context.controller_name.to_s.classify.safe_constantize
        return klass if klass && klass <= ActiveRecord::Base
      end
      table.model
    end

    # Relation without pagination nor order
    def base_relation
      relation = model.all
      Array(table.options[:scope]).each { |scope| relation = relation.public_send(scope) }
      relation = relation.select(select_clause) if select_clause
      relation = relation.from(Evaluation.value(context, table.options[:from])) if table.options[:from]
      relation = relation.where(conditions) if table.options[:conditions].present?
      relation = relation.joins(table.options[:joins]) if table.options[:joins].present?
      reflections = table.reflections.map(&:name)
      relation = relation.includes(*reflections).references(*reflections) if reflections.any?
      relation
    end

    # Ordered relation, without pagination
    def relation
      relation = base_relation
      relation = relation.group(table.options[:group]) if table.options[:group].present?
      relation.reorder(state.order)
    end

    # Records for the current page (or all records if not paginated)
    def records(paginate: table.paginate?)
      base = base_relation
      @count = table.options[:count].present? ? base.count(table.options[:count]) : base.count
      @count = @count.size if @count.is_a?(Hash)
      ordered = relation
      return ordered unless paginate

      @limit = (state[:per_page] || 25).to_i
      @limit = 25 if @limit <= 0
      request_params = context.respond_to?(:params) ? context.params : {}
      focus_id = request_params["#{table.name}-id"]
      @page = if request_params[:page]
                (state[:page] || 1).to_i
              elsif focus_id && (index = ordered.pluck(:id).index(focus_id.to_i))
                (index.to_f / @limit).floor + 1
              else
                1
              end
      @last_page = [(@count.to_f / @limit).ceil.to_i, 1].max
      @page = @page.clamp(1, @last_page)
      @offset = (@page - 1) * @limit
      ordered.offset(@offset).limit(@limit)
    end

    private

      def select_clause
        return nil unless table.options[:distinct] || table.options[:select]

        code = +''
        code << 'DISTINCT ' if table.options[:distinct]
        code << if table.options[:select]
                  table.options[:select].collect do |k, v|
                    c = k.is_a?(Array) ? "#{k[0]}.#{k[1]}" : k.to_s
                    c += " AS #{v}" if v.present?
                    c
                  end.join(', ')
                else
                  "#{model.table_name}.*"
                end
        Arel.sql(code)
      end

      def conditions
        conditions = table.options[:conditions]
        case conditions
        when Proc
          Evaluation.value(context, conditions)
        when Symbol
          context.send(conditions, state.options)
        when Array
          raise ArgumentError.new('First element of an Array can only be String.') unless conditions.first.is_a?(String)

          [conditions.first] + conditions[1..].map { |v| Evaluation.value(context, v) }
        when Hash
          Evaluation.deep(context, conditions)
        when String
          conditions
        else
          raise ArgumentError.new("Unsupported type for conditions: #{conditions.inspect}")
        end
      end
  end
end
