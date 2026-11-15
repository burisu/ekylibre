module Admin
  # Holds status key constants and status accessors used by both
  # the controller (status polling) and the rake task (admin:tenant:create).
  class CreateTenantJob < ApplicationJob
    STATUS_KEY = 'ekylibre:admin:create_tenant'.freeze

    def self.current_status
      result = Ekylibre::TaskStatus.read(STATUS_KEY)
      {
        status:  result['status']  || 'idle',
        message: result['message'] || '',
        tenant:  result['tenant']  || ''
      }
    end

    def self.reset!
      Ekylibre::TaskStatus.delete(STATUS_KEY)
    end
  end
end
