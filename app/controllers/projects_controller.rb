class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]
  before_action :require_login
  before_action :authorize_project!, only: [ :edit, :update ]
  before_action :delete_project_authorization!, only: [ :destroy ]

  def index
    @projects = Project.all.includes(:manager, :bugs, :assigned_users)

    # Search by project name or manager
    if params[:search].present?
      @projects = @projects.where("name ILIKE ?", "%#{params[:search]}%")
    end

    if params[:manager_id].present?
      @projects = @projects.where(manager_id: params[:manager_id])
    end

    @projects = @projects.order(created_at: :desc)
  end

  def show
    @project = Project.find(params[:id])
    if can_manage_project?(@project)
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
    @projects = current_user.projects.order(created_at: :desc) || current_user.where(projects.manager_id = :user_id)
  end

  def authorize_project!
    unless can_manage_project?(@project)
      redirect_to projects_path, alert: "You are not authorized to perform this action."
    end
  end

  def delete_project_authorization!
    unless delete_project?(@project)
      redirect_back(fallback_location: root_path, alert: "You are not authorized, only manager can delete the project.")
    end
  end

  def import_page
  end

  def import
    file = params[:file]
    if file.nil?
      redirect_to import_projects_page_path, alert: "Please select a CSV file."
      return
    end
    unless file.content_type == "text/csv" || File.extname(file.original_filename) == ".csv"
      redirect_to import_projects_page_path, alert: "Inavlid file type. Please select a CSV file only."
      return
    end

    temp_file_path = Rails.root.join("tmp", "project_import_#{Time.now.to_i}.csv")
    File.open(temp_file_path, "wb") { |f| f.write(file.read) }

    ProjectImportJob.perform_later(temp_file_path.to_s, current_user.id)

    redirect_to import_projects_results_path, notice: "Here are the results of your imports file."
  end

  def import_results
    result_file_path = Rails.root.join("tmp", "import_project_result_user_#{current_user.id}.yml")
    if File.exist?(result_file_path)
      @result = YAML.load_file(result_file_path) || { success_count: 0, failures: [] }
    else
      @result = { success_count: 0, failures: [] }
      flash.now[:notice] = "The import is still processing. Please refresh this page in a few seconds."
    end
  end

  def export
    send_data Project.to_csv, filename: "projects-#{Date.today}.csv"
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :manager_id, assigned_user_ids: [])
  end
end
