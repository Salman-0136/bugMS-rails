class ProjectExportJob
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(user_id)
    start_time = Time.now

    file_path = Projects::ProjectsExportService.new.call

    duration = Time.now - start_time

    Rails.logger.info "ProjectExportJob finished in #{duration.round(2)} seconds"

    file_path
  end
end
