module ActionIntegration
  mattr_accessor :config
  self.config = ActionIntegration::Configuration.new

  class ServiceNotIntegrated < StandardError; end

  class IntegrationParameterEmpty < StandardError; end
end
