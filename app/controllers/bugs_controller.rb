class BugsController < ApplicationController
  before_action :set_bug, only: [ :show, :edit, :update, :destroy ]
  before_action :require_login
  before_action :authorize_bug!, only: [ :edit, :update, :destroy ]
  before_action :set_project_for_new_and_create, only: [ :new, :create ]
  before_action :authorize_bug_creation!, only: [ :new, :create ]

  def index
    @bugs = Bug.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @bug = Bug.new(project: @project)
  end

  def create
    @bug = Bug.new(bug_params)
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
    @bugs = current_user.bugs.order(created_at: :desc)
  end

  private

  def set_bug
    @bug = Bug.find(params[:id])
  end

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

  def authorize_bug!
    unless can_manage_bug?(@bug)
      redirect_to bug_path(@bug), alert: "You are not authorized to perform this action."
    end
  end

  def authorize_bug_creation!
    allowed_users = @project.assigned_users.to_a + [ @project.manager ]
    unless current_user && allowed_users.include?(current_user)
      redirect_back(fallback_location: root_path, alert: "Not authorized to create bugs.")
    end
  end

  def bug_params
    params.require(:bug).permit(:title, :description, :status, :priority, :severity, :bug_type, :due_date, :project_id, user_ids: [])
  end
end
