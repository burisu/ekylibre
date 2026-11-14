class AllSensorsReadingJob < ScheduleJob
  queue_as :default

  def perform_on_tenant
    Rails.logger.info("Background sensors reading of #{Ekylibre::Tenant.current.to_s}...")
    SensorsReadingJob.perform_later
    Rails.logger.info("Background sensors reading of #{Ekylibre::Tenant.current.to_s}...")
  end
end
