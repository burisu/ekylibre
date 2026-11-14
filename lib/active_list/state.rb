# frozen_string_literal: true

module ActiveList
  # List parameters (sort, page, hidden columns...) merged from user
  # preferences, render options and request params.
  class State
    PERSISTED_KEYS = %i[sort dir page per_page hidden_columns].freeze

    attr_reader :table, :context, :options, :params

    def initialize(table, context, options = {})
      @table = table
      @context = context
      @options = (options.is_a?(Hash) ? options : {}).symbolize_keys
      request_params = context.respond_to?(:params) ? context.params : {}
      request_params = request_params.to_unsafe_h if request_params.respond_to?(:to_unsafe_h)
      @options.update(request_params.to_h.symbolize_keys)

      @params = load_preferences
      @params.update(@options)
      @params[:hidden_columns] = table.hidden_columns.map(&:name) unless @params[:hidden_columns].is_a?(Array)
      @params[:hidden_columns] = @params[:hidden_columns].map(&:to_sym)
      @params[:sort] = @params[:sort].to_s
      @params[:dir] = @params[:dir].to_s
      if table.paginate?
        @params[:page] = (@params[:page] || table.options[:page]).to_i
        @params[:per_page] = (@params[:per_page] || table.options[:per_page]).to_i
      end
    end

    def [](key)
      @params[key]
    end

    def []=(key, value)
      @params[key] = value
    end

    def hidden?(column)
      @params[:hidden_columns].include?(column.name)
    end

    # SQL order expression, as an Arel node when it comes from a column
    def order
      column = table.sortable_columns.detect { |c| c.sort_id.to_s == @params[:sort] }
      if column && column.sort_expression
        @params[:dir] = 'asc' unless %w[asc desc].include?(@params[:dir])
        nulls = @params[:dir] == 'asc' ? 'FIRST' : 'LAST'
        Arel.sql("#{column.sort_expression} #{@params[:dir].upcase} NULLS #{nulls}")
      else
        order = table.default_order
        order.is_a?(String) ? Arel.sql(order) : order
      end
    end

    def toggle_column(column_name, visibility)
      column = column_name.to_sym
      names = table.data_columns.map(&:name)
      @params[:hidden_columns].delete_if { |c| !names.include?(c) }
      @params[:hidden_columns].delete(column) if visibility == 'shown'
      @params[:hidden_columns] << column if visibility == 'hidden' && !@params[:hidden_columns].include?(column)
    end

    def save!
      user = current_user
      return unless user.respond_to?(:preference)

      preference = user.preference(table.preference_key, YAML.dump({}))
      preference.set!(YAML.dump(@params.slice(*PERSISTED_KEYS).stringify_keys))
    end

    private

      def current_user
        context.respond_to?(:current_user, true) ? context.send(:current_user) : nil
      end

      def load_preferences
        user = current_user
        return {} unless user.respond_to?(:preference)

        value = user.preference(table.preference_key, YAML.dump({})).value
        loaded = YAML.safe_load(value.to_s, permitted_classes: [Symbol], aliases: false) rescue nil
        loaded.is_a?(Hash) ? loaded.symbolize_keys.slice(*PERSISTED_KEYS) : {}
      end
  end
end
