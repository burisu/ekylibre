# frozen_string_literal: true

module ActiveList
  # Minimal context used to evaluate list Procs outside of a request
  # (e.g. in ListExportJob). Exposes `params`, `current_user` and
  # `controller_name` like a controller would.
  class JobContext
    attr_reader :params, :current_user, :controller_name

    def initialize(params:, current_user:, controller_name:)
      @params = ActionController::Parameters.new(params).permit!
      @current_user = current_user
      @controller_name = controller_name
    end
  end
end
