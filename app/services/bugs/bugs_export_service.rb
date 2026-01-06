module Bugs
  class BugsExportService
    def call
      file_path = Rails.root.join(
        "tmp",
        "bugs_export_#{Date.today.strftime('%Y%m%d')}.csv"
      )

      # Open file to write CSV
      File.open(file_path, "w") do |file|
        # Write CSV headers manually
        headers = [
          "id", "title", "description", "status", "priority",
          "severity", "bug_type", "time_lapse", "due_date",
          "project_name", "project_manager",
          "bug_assignees", "project_assignees",
          "created_at", "updated_at"
        ]
        file.puts headers.join(",")

        # Get raw PostgreSQL connection
        conn = ActiveRecord::Base.connection.raw_connection

        # Build SQL query for export
        sql = <<~SQL
          COPY (
            SELECT
              b.id,
              b.title,
              b.description,
              b.status,
              b.priority,
              b.severity,
              b.bug_type,
              b.time_lapse,
              b.due_date,
              p.name AS project_name,
              m.name AS project_manager,
              string_agg(DISTINCT u.name, ', ') AS bug_assignees,
              string_agg(DISTINCT pa.name, ', ') AS project_assignees,
              b.created_at,
              b.updated_at
            FROM bugs b
            LEFT JOIN bug_assignments bu ON bu.bug_id = b.id
            LEFT JOIN users u ON u.id = bu.user_id
            LEFT JOIN projects p ON p.id = b.project_id
            LEFT JOIN users m ON m.id = p.manager_id
            LEFT JOIN projects_users pu ON pu.project_id = p.id
            LEFT JOIN users pa ON pa.id = pu.user_id
            GROUP BY b.id, p.id, m.id
          ) TO STDOUT WITH CSV
        SQL

        # Stream PostgreSQL COPY to file
        conn.copy_data(sql) do
          while row = conn.get_copy_data
            row = row.force_encoding("UTF-8").scrub("") # fix encoding
            file.puts(row)
          end
        end
      end

      file_path
    end
  end
end
