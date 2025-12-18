# app/jobs/bug_import_job.rb
require "csv"

class BugImportJob < ApplicationJob
  queue_as :default
  BATCH_SIZE = 50_000

  def perform(file_path, user_id)
    result_file = Rails.root.join("tmp", "import_bug_result_user_#{user_id}.yml")
    result = { success_count: 0, failures: [], processing: true }
    File.write(result_file, result.to_yaml)

    begin
      failures = []
      bugs_batch = []
      project_user_cache = {} # cache allowed users per project

      CSV.foreach(file_path, headers: true).with_index(2) do |row, row_number|
        # Clean values
        row.each { |k, v| row[k] = v.to_s.strip.gsub(/\A"+|"+\z/, "") }

        project_id = row["project_id"].to_i
        bug_attrs = {
          title:       row["title"],
          description: row["description"],
          due_date:    row["due_date"],
          project_id:  project_id,
          priority:    row["priority"],
          severity:    row["severity"],
          status:      row["status"],
          bug_type:    row["bug_type"],
          created_at:  Time.current,
          updated_at:  Time.current
        }

        # Cache allowed users per project
        project_user_cache[project_id] ||= begin
          project = Project.includes(:assigned_users).find_by(id: project_id)
          if project
            (project.assigned_users.pluck(:id) + [ project.manager_id ]).compact.to_set
          else
            Set.new
          end
        end

        allowed_user_ids = project_user_cache[project_id]
        project = Project.find_by(id: project_id)

        raw_assignee_ids = row["bug_assignees"].to_s.split(/[\s,]+/).map(&:to_i).reject(&:zero?)
        assignee_ids = raw_assignee_ids.select { |id| allowed_user_ids.include?(id) }

        # Collect errors
        errors = []
        errors << "Project with ID #{project_id} not found" unless project
        errors << "Bug must have at least one assigned user" if raw_assignee_ids.blank?
        errors << "Bug must have at least one valid assignee for project '#{project&.name}'. Allowed IDs: #{allowed_user_ids.to_a.join(', ')}" if assignee_ids.blank?

        if project && assignee_ids.present?
          bug = Bug.new(bug_attrs)
          bug.project = project
          assignee_ids.each { |uid| bug.bug_assignments.build(user_id: uid) }
          errors += bug.errors.full_messages unless bug.valid?
        end

        if errors.any?
          failures << { row: row_number, errors: errors }
        else
          bugs_batch << { bug: bug_attrs, user_ids: assignee_ids }
        end

        # Bulk insert batch
        if bugs_batch.size >= BATCH_SIZE
          insert_batch!(bugs_batch)
          result[:success_count] += bugs_batch.size
          bugs_batch.clear
        end
      end

      # Insert remaining batch
      unless bugs_batch.empty?
        insert_batch!(bugs_batch)
        result[:success_count] += bugs_batch.size
      end

      # Store failures in result
      result[:failures] = failures if failures.any?

    rescue => e
      result[:failures] = [ { row: 0, errors: [ e.message ] } ]
    ensure
      result[:processing] = false
      File.write(result_file, result.to_yaml)
      File.delete(file_path) if File.exist?(file_path)
    end
  end

  private

  def insert_batch!(batch)
    return if batch.empty?

    Bug.transaction do
      inserted_bugs = Bug.insert_all!(
        batch.map { |b| b[:bug] },
        returning: %w[id]
      )

      assignments = []
      inserted_bugs.each_with_index do |bug_row, idx|
        batch[idx][:user_ids].each do |uid|
          assignments << {
            bug_id: bug_row["id"],
            user_id: uid,
            created_at: Time.current,
            updated_at: Time.current
          }
        end
      end

      BugAssignment.insert_all!(assignments) if assignments.any?
    end
  end
end
