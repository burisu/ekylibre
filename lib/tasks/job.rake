# Inspection of the Solid Queue jobs. JOB_CLASS and TENANT filter jobs.
namespace :job do
  matching = lambda do |scope|
    jobs = scope
    jobs = jobs.where(class_name: ENV['JOB_CLASS']) if ENV['JOB_CLASS']
    jobs = jobs.to_a
    jobs.select! { |job| job.arguments['tenant'] == ENV['TENANT'] } if ENV['TENANT']
    jobs
  end

  describe = ->(job) { "#{job.class_name} on #{job.arguments['tenant'] || 'public'} (queue #{job.queue_name})" }

  desc 'Discards all pending, scheduled and failed jobs'
  task clear: :environment do
    SolidQueue::Job.where(finished_at: nil).find_each(&:discard)
    puts 'Pending jobs cleared'
  end

  desc 'Lists running and pending jobs matching JOB_CLASS/TENANT'
  task running: :environment do
    jobs = matching.call(SolidQueue::Job.where(finished_at: nil).order(:created_at))
    puts "\nMatching running jobs:" if jobs.any?
    jobs.each { |job| puts " - #{describe.call(job)}" }
    jobs.any?
  end

  desc 'Lists finished jobs matching JOB_CLASS/TENANT'
  task done: :environment do
    jobs = matching.call(SolidQueue::Job.finished.order(:finished_at))
    puts "\nMatching jobs done:" if jobs.any?
    jobs.each { |job| puts " - #{describe.call(job)}\n     — Finished at #{job.finished_at}" }
    jobs.any?
  end

  desc 'Displays all matching errored jobs'
  task errored: :environment do
    jobs = matching.call(SolidQueue::Job.failed.includes(:failed_execution).order(:created_at))
    puts "\nMatching errored jobs:" if jobs.any?
    jobs.each do |job|
      error = job.failed_execution
      puts " - #{describe.call(job)} with error \"#{error.exception_class}: #{error.message}\""
    end
    jobs.any?
  end

  desc 'Displays all infos available for matching job (JOB_CLASS/TENANT)'
  task job_status: %i[running done]

  task status: :environment do
    puts 'Queues:'
    SolidQueue::Queue.all.each do |queue|
      puts " #{queue.name}: #{queue.size} job(s)#{' (paused)' if queue.paused?}"
    end
    processes = SolidQueue::Process.all
    puts "#{processes.size} Processes:"
    processes.each do |process|
      puts " - #{process.kind} #{process.name} on #{process.hostname}, PID: #{process.pid}, last heartbeat #{process.last_heartbeat_at}"
    end
  end
end

desc 'Show jobs status'
task job: 'job:status'
