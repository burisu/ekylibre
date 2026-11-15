# frozen_string_literal: true

# Base class of all jobs. The tenant current at enqueue time is serialized
# with the job and switched to before performing it (replaces the
# apartment-sidekiq middleware; works with any ActiveJob backend).
class ApplicationJob < ActiveJob::Base
  attr_writer :tenant

  def tenant
    @tenant ||= Apartment::Tenant.current
  end

  def serialize
    super.merge('tenant' => tenant)
  end

  def deserialize(job_data)
    super
    self.tenant = job_data['tenant']
  end

  around_perform do |job, block|
    if job.tenant.blank? || job.tenant == Apartment.default_tenant.to_s
      block.call
    else
      Ekylibre::Tenant.switch(job.tenant) { block.call }
    end
  end
end
