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

  private
  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :manager_id, assigned_user_ids: [])
  end
end
