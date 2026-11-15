# frozen_string_literal: true

module ActiveList
  module Integration
    # Controller DSL: `list(name = controller_name, options = {}) { |t| ... }`
    module ActionController
      extend ActiveSupport::Concern

      included do
        class_attribute :active_list_tables, instance_writer: false, default: {}
      end

      class_methods do
        def list(*args, &block)
          options = args.extract_options!
          name = (args.shift || controller_name).to_sym
          model = (options.delete(:model) || name).to_s.classify.constantize
          options[:controller] = self
          table = ActiveList::Definition::Table.new(name, model, options)
          block ? yield(table) : table.load_default_columns

          self.active_list_tables = active_list_tables.merge(name => table)
          define_method(table.action_name) { active_list_action(name) }
          table
        end

        # Finds a list definition in this controller or its ancestors
        # Without name, looks for a list named after the controller or one of
        # its ancestors (like the former gem did).
        def active_list_table(name = nil)
          return active_list_tables[name.to_sym] if name

          klass = self
          while klass.respond_to?(:active_list_tables)
            table = active_list_tables[klass.controller_name.to_sym]
            return table if table

            klass = klass.superclass
          end
          nil
        end
      end

      private

        def active_list_action(name)
          table = self.class.active_list_table(name)
          state = ActiveList::State.new(table, self)
          respond_to do |format|
            format.html do
              if request.xhr?
                if params[:column] && params[:visibility]
                  state.toggle_column(params[:column], params[:visibility])
                  state.save!
                  head :ok
                  return
                end
                options = params[:only] ? { only: params[:only] } : {}
                render html: ActiveList::Renderer.new(table, view_context, options).render
              else
                render html: ActiveList::Renderer.new(table, view_context).render, layout: false
              end
            end
            ActiveList.export_formats.each do |export_format|
              format.public_send(export_format) { active_list_export(table, export_format) }
            end
          end
          state.save!
        end

        def active_list_export(table, format)
          export_class = table.options[:export_class]
          exporter = ActiveList::Exporters.new(table, self)
          if export_class
            export_params = params.to_unsafe_h.except(:format)
            export_class.perform_later(user: current_user,
                                       controller: self.class.name,
                                       list: table.name.to_s,
                                       params: export_params,
                                       file_name: exporter.file_name,
                                       format: format.to_s,
                                       file_extension: exporter.file_extension(format))
            notify_success(:document_in_preparation)
            redirect_back(fallback_location: root_path)
          else
            send_data(exporter.generate(format),
                      type: exporter.mime_type(format),
                      disposition: 'inline',
                      filename: "#{exporter.file_name.parameterize}.#{exporter.file_extension(format)}")
          end
        end
    end

    # View helper: `list(name = controller_name, options = {})`
    module ViewsHelper
      def list(*args, &block)
        options = args.extract_options!
        name = args.shift
        table = controller.class.active_list_table(name)
        raise ArgumentError.new("Unknown list #{name.inspect} in #{controller.class.name}") unless table

        ActiveList::Renderer.new(table, self, options).render(&block)
      end
    end
  end
end
