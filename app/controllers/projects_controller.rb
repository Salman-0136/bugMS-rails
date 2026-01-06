class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]
  before_action :authenticate_user!
  load_and_authorize_resource

  PER_PAGE = 6

  def index
    @projects = Project.all.includes(:manager, :assigned_users)

    # Search
    @projects = @projects.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @projects = @projects.where(manager_id: params[:manager_id]) if params[:manager_id].present?

    @projects = @projects.order(created_at: :desc).page(params[:page]).per(PER_PAGE)
  end

  def show
    # Load bugs only if user can manage project
    if can?(:manage, @project)
      @bugs = @project.bugs.order(created_at: :desc)
      @bugs = @bugs.where(priority: params[:priority]) if params[:priority].present?
      @bugs = @bugs.where(status: params[:status]) if params[:status].present?
      @bugs = @bugs.where(bug_type: params[:bug_type]) if params[:bug_type].present?
      @bugs = @bugs.where(severity: params[:severity]) if params[:severity].present?
      @bugs = @bugs.page(params[:page]).per(12)
    end
  end

  def new
    @project = Project.new
    @users = User.where.not(is_admin: true).order(:name)
  end

  def create
    @project = Project.new(project_params)
    @users = User.where.not(is_admin: true).order(:name)
    if @project.save
      redirect_to @project, notice: "Project created successfully."
    else
      flash.now[:alert] = "Error creating project."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.where.not(is_admin: true).order(:name)
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated successfully."
    else
      flash.now[:alert] = "Error updating project."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted successfully."
  end

  def my_projects
    @projects = Project
                  .left_joins(:assigned_users)
                  .where("projects.manager_id = :user_id OR users.id = :user_id", user_id: current_user.id)
                  .order(created_at: :desc)
                  .distinct
                  .page(params[:page])
                  .per(PER_PAGE)
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
      redirect_to import_projects_page_path, alert: "Please upload a valid CSV file."
      return
    end

    input_path = Rails.root.join(
      "tmp",
      "projects_import_#{Time.now.to_i}.csv"
    )

    FileUtils.cp(uploaded_file.path, input_path)

    error_filename = "project_import_errors_#{Time.now.to_i}.csv"

    ProjectImportJob.perform_async(
      current_user.id,
      input_path.to_s,
      error_filename
    )

    redirect_to import_projects_page_path(
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
      redirect_to import_projects_page_path, alert: "Error file not found"
    end
  end

  def export
    ProjectExportJob.perform_async(current_user.id)

    redirect_to projects_path, notice: "Projects export started. Refresh page to download when ready"
  end

  def export_download
    file_path = Rails.root.join("tmp", "projects_export_#{Date.today.strftime('%Y%m%d')}.csv")

    unless file_path && File.exist?(file_path)
      redirect_to projects_path, alert: "Export not ready yet."
      return
    end

    send_file file_path,
              filename: File.basename(file_path),
              type: "text/csv",
              disposition: "attachment"
  end

  private

  def set_project
    @project = Project.find(params[:id])
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

  def project_params
    params.require(:project).permit(:name, :description, :manager_id, assigned_user_ids: [])
  end
end
