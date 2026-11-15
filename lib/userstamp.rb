module Userstamp
end

ActionController::Base.send(:include, Userstamp::Controller)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Userstamp::MigrationHelper)
