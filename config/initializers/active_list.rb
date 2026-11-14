# frozen_string_literal: true

require 'active_list'

ActiveSupport.on_load(:action_controller_base) do
  include ActiveList::Integration::ActionController
end

ActiveSupport.on_load(:action_view) do
  include ActiveList::Integration::ViewsHelper
end

# Sets default temporary in Rails tmp dir by default
ActiveList.temporary_directory = if Rails.env.development?
                                   -> { Rails.root.join('tmp', 'exports', 'active_list') }
                                 else
                                   -> { Ekylibre::Tenant.private_directory.join('tmp') }
                                 end
