class BugsController < ApplicationController
  load_and_authorize_resource except: [ :new, :create, :project_bugs, :my_bugs, :import_page, :import, :download_import_errors, :export ]
  before_action :set_project_for_new_and_create, only: [ :new, :create ]

  def index
    if current_user.is_admin?
      # Admin sees all bugs
      @bugs = Bug
                .includes(:users, project: [ :manager, :assigned_users ])
                .order(created_at: :desc)
                .page(params[:page])
                .per(20)
    else
      # Regular users see only their assigned bugs or bugs in their projects
      @bugs = Bug
                .left_joins(:users)
                .left_joins(project: :assigned_users)
                .where(
                  "users.id = :user_id
                  OR projects.manager_id = :user_id
                  OR projects_users.user_id = :user_id",
                  user_id: current_user.id
                )
                .includes(:users, project: [ :manager, :assigned_users ])
                .distinct
                .order(created_at: :desc)
                .page(params[:page])
                .per(20)
    end
  end

  def show
  end

  def new
    @bug = Bug.new(project: @project)
    authorize! :create, @bug
  end

  def create
    @bug = Bug.new(bug_params)
    @bug.project = @project
    authorize! :create, @bug
    if @bug.save
      redirect_to @bug, notice: "Bug was successfully created."
    else
      flash.now[:alert] = "Please fix the errors below."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @project = @bug.project
  end

  def update
    if params.dig(:bug, :close_request)
      # Convert string to time if needed
      completed_at = params.dig(:bug, :completed_at) || Time.current
      @bug.close!(completed_at)
      redirect_to @bug, notice: "Bug closed successfully!"

    elsif params.dig(:bug, :reopen_request)
      if @bug.reopen!
        redirect_to @bug, notice: "Bug reopened successfully!"
      else
        redirect_to @bug, alert: @bug.errors.full_messages.join(", ")
      end

    elsif @bug.update(bug_params)
      redirect_to @bug, notice: "Bug was successfully updated."
    else
      flash.now[:alert] = "Please fix the errors below."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bug.destroy
    redirect_to bugs_url, notice: "Bug was successfully destroyed."
  end

  def my_bugs
    # Authorize generalized access, specific bugs are filtered in the query

    @bugs = current_user.bugs
                        .order(created_at: :desc)
                        .page(params[:page])
                        .per(15)
  end


  def project_bugs
    @project = Project.find(params[:project_id])

    authorize! :view_bugs, @project

    @bugs = @project.bugs
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(20)
  end

  def import_page
    return unless params[:import_file]

    file_path = Rails.root.join("tmp", params[:import_file])
    return unless File.exist?(file_path)

    @success_count, @failure_count =
      read_import_counts(file_path)

    @error_file = params[:import_file]
  end

  def import
    uploaded_file = params[:file]

    if uploaded_file.nil? || File.extname(uploaded_file.original_filename) != ".csv"
      redirect_to import_bugs_page_path, alert: "Please upload a valid CSV file."
      return
    end

    input_path = Rails.root.join(
      "tmp",
      "bugs_import_#{Time.now.to_i}.csv"
    )

    FileUtils.cp(uploaded_file.path, input_path)

    error_filename = "bug_import_errors_#{Time.now.to_i}.csv"

    BugImportJob.perform_async(
      current_user.id,
      input_path.to_s,
      error_filename
    )

    redirect_to import_bugs_page_path(
      import_file: error_filename
    ), notice: "Import started…"
  end

  def download_import_errors
    filename = params[:file]
    file_path = Rails.root.join("tmp", filename)

    if filename.present? && File.exist?(file_path)
      send_file file_path,
                filename: filename,
                type: "text/csv",
                disposition: "attachment"
    else
      redirect_to import_bugs_page_path, alert: "Error file not found"
    end
  end

  def export
    BugExportJob.perform_async(current_user.id)

    redirect_to bugs_path, notice: "Bugs export started. Refresh page to download when ready"
  end

  def export_download
    file_path = Rails.root.join("tmp", "bugs_export_#{Date.today.strftime('%Y%m%d')}.csv")

    unless file_path && File.exist?(file_path)
      redirect_to bugs_path, alert: "Export not ready yet."
      return
    end

    send_file file_path,
              filename: File.basename(file_path),
              type: "text/csv",
              disposition: "attachment"
  end

  private

  # Instead of relying on params[:project_id], fetch project from bug_params[:project_id]
  def set_project_for_new_and_create
    project_id = params.dig(:bug, :project_id) || params[:project_id]
    unless project_id.present?
      flash[:alert] = "Please select a project first."
      redirect_to projects_path
      return
    end

    @project = Project.find(project_id)
  end

  def read_import_counts(file_path)
    success = 0
    failure = 0

    File.foreach(file_path) do |line|
      break unless line.start_with?("#")

      key, value = line.delete("#").strip.split(",")
      success  = value.to_i if key == "success_count"
      failure  = value.to_i if key == "failure_count"
    end

    [ success, failure ]
  end

  def bug_params
    params.require(:bug).permit(:title, :description, :status, :priority, :severity, :bug_type, :due_date, :project_id, user_ids: [])
  end
end
