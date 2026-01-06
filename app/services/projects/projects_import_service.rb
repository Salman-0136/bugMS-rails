require "csv"

module Projects
  class ProjectsImportService
    attr_reader :success_count, :failure_count, :error_file_path

    BATCH_SIZE = 10_000
    TIME = Time.current

    def initialize(file_path)
      @file_path     = file_path
      @success_count = 0
      @failure_count = 0

      @error_file_path = Rails.root.join("tmp", "project_import_errors_#{Time.now.to_i}.csv")
    end

    def call
      users = User.where.not(id: 3).index_by(&:id) # exclude admin

      valid_projects = []
      project_user_rows = []

      CSV.open(@error_file_path, "w") do |error_csv|
        # --- CSV HEADER ---
        error_csv << [ "# success_count", 0 ]
        error_csv << [ "# failure_count", 0 ]
        error_csv << [ "row", "error" ]

        CSV.foreach(@file_path, headers: true).with_index(2) do |row, line|
          name        = row["name"].to_s.strip
          description = row["description"].to_s.strip
          manager_id  = row["manager_id"].to_i

          unless users.key?(manager_id)
            write_error(error_csv, line, "Invalid manager ID #{manager_id}")
            next
          end

          assignee_ids = row["assigned_user_ids"].to_s.split(",").map(&:to_i)
          valid_assignees = assignee_ids & users.keys

          if assignee_ids.any? && valid_assignees.empty?
            write_error(
              error_csv,
              line,
              "Invalid assignee IDs #{assignee_ids.join(', ')}"
            )
            next
          end

          valid_projects << {
            name: name,
            description: description,
            manager_id: manager_id,
            created_at: TIME,
            updated_at: TIME
          }

          project_user_rows << valid_assignees
        end
      end

      insert_projects(valid_projects, project_user_rows)
      update_final_counts

      self
    end

    private

    def insert_projects(projects, project_user_rows)
      projects.each_slice(BATCH_SIZE).with_index do |batch, batch_idx|
        result = Project.insert_all!(batch, returning: [ :id ])
        project_ids = result.rows.flatten

        project_ids.each_with_index do |project_id, idx|
          user_ids = project_user_rows[idx + batch_idx * BATCH_SIZE]
          next if user_ids.blank?

          ProjectsUser.insert_all!(
            user_ids.map do |user_id|
              {
                project_id: project_id,
                user_id: user_id
              }
            end
          )
        end

        @success_count += batch.size
      end
    end

    def write_error(csv, line, message)
      @failure_count += 1
      csv << [ line, message ]
    end

    def update_final_counts
      lines = File.open(@error_file_path, "r+").readlines
      lines[0] = "# success_count, #{@success_count}\n"
      lines[1] = "# failure_count, #{@failure_count}\n"
      File.open(@error_file_path, "w") { |f| f.write(lines.join) }
    end
  end
end
