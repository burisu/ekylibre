# frozen_string_literal: true

# Builds standard RESTful actions to manage records of a model.
#
# Actions are defined with define_method at class definition: no Ruby source
# is generated nor evaluated. Dynamic options are given as Procs:
# * Proc without argument: evaluated in the controller (e.g. `-> { params[:id] }`)
# * Proc with one argument: receives the current record
#   (e.g. `redirect_to: ->(record) { { action: :show, id: record.id } }`)
module RestfullyManageable
  extend ActiveSupport::Concern

  OPTION_KEYS = %i[t3e creation_t3e redirect_to xhr destroy_to subclass_inheritance partial multipart except only cancel_url scope identifier continue model_name].freeze
  NEW_IGNORED_COLUMNS = %i[depth rgt lft id lock_version updated_at updater_id creator_id created_at].freeze

  # Runtime configuration of the generated actions
  class Config
    attr_reader :options, :defaults, :model_name, :record_name, :controller_path, :after_save_url, :after_destroy_url, :notify_after_save, :new_columns

    def initialize(controller, defaults)
      @defaults = defaults.dup
      @options = @defaults.extract!(*OPTION_KEYS)
      @controller_path = controller.controller_path
      @model_name = @options[:model_name] || controller.controller_name.to_s.classify
      @record_name = @model_name.underscore.singularize
      model = @model_name.constantize
      columns = model.columns_definition.keys

      @after_save_url = @options[:redirect_to]
      if @after_save_url.blank?
        if controller.instance_methods(true).include?(:show) || actions.include?(:show)
          @after_save_url = :show
        elsif controller.instance_methods(true).include?(:index) || actions.include?(:index)
          @after_save_url = :index
        end
      end
      @notify_after_save = @after_save_url != :show
      @after_destroy_url = @options[:destroy_to] || :index

      @options[:identifier] ||= %w[name number id].detect { |i| columns.include?(i) }
      raise 'Need a :identifier option' if @options[:identifier].blank?

      @options[:cancel_url] ||= actions.include?(:index) ? { action: :index } : :back
      @after_save_url = @options[:cancel_url] if @after_save_url.blank?
      @new_columns = columns.map(&:to_sym).uniq.reject do |c|
        NEW_IGNORED_COLUMNS.include?(c) || c.blank? || c.to_s.end_with?('_attributes')
      end
    end

    def actions
      @actions ||= begin
        list = %i[index show new create edit update destroy]
        list &= Array(@options[:only]) if @options[:only]
        list -= Array(@options[:except]) if @options[:except]
        list
      end
    end

    def model
      @model_name.constantize
    end
  end

  private

    # Instance helpers used by generated actions
    def restfully_config
      self.class.restfully_manageable_config
    end

    def restfully_value(value, record = nil)
      case value
      when Proc
        value.arity.zero? ? instance_exec(&value) : instance_exec(record, &value)
      when Hash
        value.transform_values { |v| restfully_value(v, record) }
      else
        value
      end
    end

    # Resolves a redirection option (:show, :index, Symbol method, Hash, Proc)
    def restfully_url(value, record)
      case value
      when :show then { action: :show, id: ->(saved) { saved.id } }
      when :index then { action: :index }
      when :back then :back
      when Symbol then send(value)
      else restfully_value(value, record)
      end
    end

    def restfully_find
      config = restfully_config
      options = config.options[:scope] ? { scope: config.options[:scope] } : {}
      record = find_and_check(config.record_name.to_sym, **options)
      instance_variable_set("@#{config.record_name}", record) if record
      record
    end

    def restfully_t3e(record)
      t3e = restfully_config.options[:t3e]
      attributes = record.attributes
      if t3e
        attributes = attributes.merge(t3e.transform_values do |v|
          v.is_a?(Symbol) ? record.public_send(v) : restfully_value(v, record)
        end)
      end
      t3e(attributes)
    end

    def restfully_render_form
      config = restfully_config
      options = {}
      options[:partial] = config.options[:partial] if config.options[:partial]
      options[:multipart] = true if config.options[:multipart]
      options[:locals] = { cancel_url: config.options[:cancel_url], with_continue: config.options[:continue] ? true : false }
      render(**options)
    end

    def resource_model
      restfully_config.model
    end

    def permitted_params
      params.require(restfully_config.record_name.to_sym).permit!
    end

  module ClassMethods
    # Configuration of manage_restfully, inherited from superclasses
    def restfully_manageable_config
      @restfully_manageable_config || (superclass.respond_to?(:restfully_manageable_config) ? superclass.restfully_manageable_config : nil)
    end

    # Build standard RESTful actions to manage records of a model
    def manage_restfully(defaults = {})
      config = Config.new(self, defaults)
      @restfully_manageable_config = config
      record_name = config.record_name
      actions = config.actions

      respond_to :html, :xml, :json

      mod = Module.new

      if actions.include?(:index)
        mod.define_method(:index) do
          respond_to do |format|
            format.html
            format.xml  { render xml:  resource_model.all }
            format.json { render json: resource_model.all }
          end
        end
      end

      if actions.include?(:show)
        parents = [self]
        parents << parents.last.superclass while parents.last.superclass < ActionController::Base
        lookup = Ekylibre::Application.config.x.restfully_manageable.view_paths
                                      .map { |dir| dir.join("{#{parents.map(&:controller_path).join(',')}}") }
        has_show = Dir.glob(lookup.map { |path| path.join('show.*') }).any?
        has_index = Dir.glob(lookup.map { |path| path.join('index.*') }).any?
        unless has_show || has_index
          raise StandardError.new("Cannot build a default show action without view for show or index actions in #{parents.map(&:controller_path).to_sentence(locale: :eng)} (#{lookup.join('show.*')}).")
        end

        subclass_inheritance = config.options[:subclass_inheritance]
        model_name = config.model_name
        name = controller_name
        mod.define_method(:show) do
          return unless (record = restfully_find)

          unless has_show
            redirect_to action: :index, "#{name}-id" => record.id
            return
          end
          if subclass_inheritance && record.type && record.type != model_name && !request.xhr?
            redirect_to controller: record.type.tableize, action: :show, id: record.id, format: params[:format]
            return
          end
          respond_to do |format|
            format.html { restfully_t3e(record) }
            format.xml  { render xml: record }
            format.json
          end
        end
      end

      if config.options[:subclass_inheritance] && self != Backend::BaseController
        inherited_defaults = defaults
        define_singleton_method(:inherited) do |subclass|
          super(subclass)
          subclass.manage_restfully(inherited_defaults)
        end
      end

      if actions.include?(:new)
        new_defaults = config.defaults
        xhr = config.options[:xhr]
        creation_t3e = config.options[:creation_t3e].is_a?(TrueClass)
        new_columns = config.new_columns
        mod.define_method(:new) do
          values = new_columns.map { |attr| [attr, params[attr]] }.to_h
          values.merge!(new_defaults.transform_values { |v| restfully_value(v) })
          record = resource_model.new(values)
          instance_variable_set("@#{record_name}", record)
          if xhr && request.xhr?
            render partial: xhr.is_a?(String) ? xhr : 'detail_form'
          else
            restfully_t3e(record) if creation_t3e
            restfully_render_form
          end
        end
      end

      if actions.include?(:create)
        creation_t3e = config.options[:creation_t3e].is_a?(TrueClass)
        continue_attributes = config.options[:continue].is_a?(Array) ? config.options[:continue] : []
        mod.define_method(:create) do
          record = resource_model.new(permitted_params)
          instance_variable_set("@#{record_name}", record)
          url = if params[:create_and_continue]
                  { action: :new, continue: true }.merge(continue_attributes.map { |attr| [attr, record.public_send(attr)] }.to_h)
                else
                  params[:redirect] || restfully_url(config.after_save_url, record)
                end
          notify = if config.notify_after_save
                     :record_x_created
                   else
                     (params[:create_and_continue] || params[:redirect]) ? :record_x_created : false
                   end
          return if save_and_redirect(record, url: url, notify: notify, identifier: config.options[:identifier])

          restfully_t3e(record) if creation_t3e
          restfully_render_form
        end
      end

      if actions.include?(:edit)
        mod.define_method(:edit) do
          return unless (record = restfully_find)

          restfully_t3e(record)
          restfully_render_form
        end
      end

      if actions.include?(:update)
        mod.define_method(:update) do
          return unless (record = restfully_find)

          restfully_t3e(record)
          record.attributes = permitted_params
          notify = config.notify_after_save || params[:redirect] ? :record_x_updated : false
          url = params[:redirect] || restfully_url(config.after_save_url, record)
          return if save_and_redirect(record, url: url, notify: notify, identifier: config.options[:identifier])

          restfully_render_form
        end
      end

      if actions.include?(:destroy)
        path = controller_path
        destroyable = config.model.method_defined?(:destroyable?)
        mod.define_method(:destroy) do
          return unless (record = restfully_find)

          if !destroyable || record.destroyable?
            record.destroy
            notify_success(:record_has_been_correctly_removed)
          else
            notify_error(:record_cannot_be_removed)
          end
          url = if config.after_destroy_url == :index
                  { controller: "/#{path}", action: :index }
                else
                  restfully_url(config.after_destroy_url, record)
                end
          redirect_to(params[:redirect] || url) unless request.xhr?
        end
      end

      include mod
      self
    end

    # Build standard actions to sort records of a model (acts_as_list)
    def manage_restfully_list(order_by = :id)
      record_name = controller_name.to_s.singularize
      model = record_name.classify.constantize
      raise ArgumentError.new("Unknown column for #{model.name}") unless model.columns_definition[order_by]

      reorder = lambda do |record|
        position = record.position_column
        records = model.where(record.scope_condition).order(Arel.sql("#{position}, #{order_by}"))
        count = records.count(position)
        unless count == records.distinct.count(position) && records.sum(position) == count * (count + 1) / 2
          records.each_with_index do |item, i|
            model.where(id: item.id).update_all(position => i + 1)
          end
        end
      end

      mod = Module.new
      mod.define_method(:up) do
        return unless (record = find_and_check(record_name.to_sym))

        record.move_higher
        reorder.call(record)
        redirect_to_back
      end
      mod.define_method(:down) do
        return unless (record = find_and_check(record_name.to_sym))

        record.move_lower
        reorder.call(record)
        redirect_to_back
      end
      include mod
      self
    end

    def manage_restfully_picture
      record_name = controller_name.to_s.singularize
      mod = Module.new
      mod.define_method(:picture) do
        return unless (record = find_and_check(record_name.to_sym))

        if record.picture.file?
          send_file(record.picture.path(params[:style] || :original))
        else
          head :not_found
        end
      end
      include mod
      self
    end
  end
end
