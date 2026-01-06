require "csv"

module Projects
  class ProjectsExportService
    def call
      file_path = Rails.root.join(
        "tmp",
        "projects_export_#{Date.today.strftime('%Y%m%d')}.csv"
      )

      File.open(file_path, "w") do |file|
        headers = [
          "id", "name", "description", "manager_name", "project_assignees"
        ]

        file.puts headers.join(",")

        conn = ActiveRecord::Base.connection.raw_connection

        sql = <<-SQL
          COPY (
            SELECT
            p.id,
            p.name,
            p.description,
            m.name AS manager_name,
            string_agg(DISTINCT u.name, ', ') AS project_assignees
            FROM projects p
            LEFT JOIN users m ON m.id = p.manager_id
            LEFT JOIN projects_users pu ON pu.project_id = p.id
            LEFT JOIN users u ON u.id = pu.user_id
            GROUP BY p.id, m.id
          ) TO STDOUT WITH CSV
        SQL

        conn.copy_data(sql) do
          while row = conn.get_copy_data
            row = row.force_encoding("UTF-8").scrub("")
            file.puts(row)
          end
        end
      end
      file_path
    end
  end
end
