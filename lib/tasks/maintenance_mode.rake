# frozen_string_literal: true

namespace :maintenance do
  desc 'Put the application in maintenance mode (ALLOWED_IPS=1.2.3.4,5.6.7.8)'
  task start: :environment do
    settings = { 'started_at' => Time.now.utc.iso8601, 'allowed_ips' => ENV['ALLOWED_IPS'].to_s.split(',') }
    File.write(Ekylibre::Middleware::Maintenance.flag_path, settings.to_yaml)
    puts 'Maintenance mode enabled'
  end

  desc 'Leave maintenance mode'
  task end: :environment do
    FileUtils.rm_f(Ekylibre::Middleware::Maintenance.flag_path)
    puts 'Maintenance mode disabled'
  end
end
