class ProjectImportJob < ApplicationJob
  queue_as :default

  def perform(file_path, user_id)
    result = { success_count: 0, failures: [] }

    CSV.foreach(file_path, headers: true).with_index(2) do |row, line|
      project = Project.new(
      name: row["name"],
      description: row["description"],
      manager_id: row["manager_id"],
      created_at: row["created_at"],
      updated_at: row["updated_at"]
    )
      if row["assigned_users"].present?
        user_ids = row["assigned_users"].split(",").map(&:strip)
        project.assigned_user_ids = user_ids
      end

      begin
        project.save!
        result[:success_count] += 1
      rescue => e
        Rails.logger.error "Row #{line} FAILED: #{e.message}"
        result[:failures] << "Row #{line}: #{e.message}"
      end
    end

    result_file_path = Rails.root.join("tmp", "import_project_result_user_#{user_id}.yml")
    File.open(result_file_path, "w") { |f| f.puts result.to_yaml }

  ensure
    File.delete(file_path) if File.exist?(file_path)
  end
end
