class BugImportJob
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(user_id, input_path, error_filename)
    start_time = Time.now
    service = Bugs::BugsImportService.new(input_path)
    service.call

    duration = Time.now - start_time


    Rails.logger.info "BugImportJob finished in #{duration.round(2)} seconds"

    # rename error file to predictable name
    File.rename(
      service.error_file_path,
      Rails.root.join("tmp", error_filename)
    )
  end
end
