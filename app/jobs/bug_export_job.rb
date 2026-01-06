class BugExportJob
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(user_id)
    start_time = Time.now

    file_path = Bugs::BugsExportService.new.call

    duration = Time.now - start_time

    Rails.logger.info "BugExportJob finished in #{duration.round(2)} seconds"

    file_path
  end
end
