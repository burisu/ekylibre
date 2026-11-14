# frozen_string_literal: true

require 'csv'

# In-app replacement of the ekylibre/active_list gem.
#
# Lists are declared in controllers with the same DSL as before:
#
#   list(conditions: list_conditions, line_class: ->(r) { r.state }) do |t|
#     t.column :number, url: true
#     t.action :edit
#   end
#
# Unlike the gem, nothing is compiled to Ruby source: definitions are plain
# objects interpreted at request time. Dynamic values are given as Procs:
#
# * a Proc without argument is evaluated in the rendering context (view,
#   controller or ActiveList::JobContext), so it can use `params`,
#   `current_user`...
# * a Proc with one argument receives the current record.
# * a Symbol given for a record-related option is sent to the record.
module ActiveList
  autoload :Evaluation, 'active_list/evaluation'
  autoload :Definition, 'active_list/definition'
  autoload :State,      'active_list/state'
  autoload :Query,      'active_list/query'
  autoload :Renderer,   'active_list/renderer'
  autoload :Exporters,  'active_list/exporters'
  autoload :JobContext, 'active_list/job_context'
  autoload :Integration, 'active_list/integration'

  mattr_accessor :export_formats, default: %i[ods csv xcsv]

  class << self
    # Pathname or callable
    attr_writer :temporary_directory

    def temporary_directory
      dir = @temporary_directory || Pathname(Dir.tmpdir)
      dir.respond_to?(:call) ? dir.call : dir
    end
  end
end
