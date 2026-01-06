require "csv"

module Bugs
  class BugsImportService
    attr_reader :error_file_path, :success_count, :failure_count

    BATCH_SIZE = 500_000       # for bugs
    ASSIGNMENT_BATCH_SIZE = 500_000  # for BugAssignments

    TIME = Time.now

    def initialize(file_path)
      @file_path       = file_path
      @success_count   = 0
      @failure_count   = 0
      @error_file_path = Rails.root.join("tmp", "bug_import_errors_#{Time.now.to_i}.csv")
    end

    def call
      projects = Project.includes(:assigned_users).index_by(&:id)
      valid_bugs = []
      bug_user_rows = []

      CSV.open(@error_file_path, "w") do |error_csv|
        error_csv << [ "# success_count", 0 ]
        error_csv << [ "# failure_count", 0 ]
        error_csv << [ "row", "error" ]

        CSV.foreach(@file_path, headers: true).with_index(2) do |row, line|
          title      = row["title"].to_s.strip
          project_id = row["project_id"].to_i
          project    = projects[project_id]

          unless project
            write_error(error_csv, line, "Invalid project ID #{project_id} for '#{title}'")
            next
          end

          assignee_ids   = row["bug_assignees"].to_s.split(",").map(&:to_i)
          valid_user_ids = project.assigned_users.pluck(:id)
          assignable_ids = assignee_ids & valid_user_ids

          if assignable_ids.empty?
            write_error(error_csv, line, "Invalid assignees #{assignee_ids} for '#{title}'")
            next
          end

          valid_bugs << {
            title: title,
            description: row["description"].to_s.strip,
            status: row["status"],
            priority: row["priority"],
            severity: row["severity"],
            bug_type: row["bug_type"],
            time_lapse: row["time_lapse"].to_s.strip,
            due_date: row["due_date"],
            project_id: project_id,
            created_at: TIME,
            updated_at: TIME
          }

          bug_user_rows << assignable_ids
        end
      end

      update_final_counts
      insert_bugs(valid_bugs, bug_user_rows)

      self
    end

    private

    def insert_bugs(bugs, bug_user_rows)
      bug_id_mapping = []  # store bug_id => assignees
      bugs.each_slice(BATCH_SIZE).with_index do |batch, batch_idx|
        result = Bug.insert_all(batch, returning: [ :id ])
        bug_ids = result.rows.flatten

        bug_ids.each_with_index do |bug_id, idx|
          user_ids = bug_user_rows[idx + batch_idx * BATCH_SIZE]
          next if user_ids.empty?

          # collect for batch insert
          user_ids.each do |user_id|
            bug_id_mapping << { bug_id:, user_id:, created_at: TIME, updated_at: TIME }
          end
        end

        @success_count += batch.size
      end

      # --- Insert BugAssignments in batches ---
      bug_id_mapping.each_slice(ASSIGNMENT_BATCH_SIZE) do |assignment_batch|
        BugAssignment.insert_all!(assignment_batch)
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
