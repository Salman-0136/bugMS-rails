class BugsController < ApplicationController
  before_action :set_bug, only: [ :show, :edit, :update, :destroy ]
  before_action :require_login
  before_action :authorize_bug!, only: [ :edit, :update, :destroy ]
  before_action :set_project_for_new_and_create, only: [ :new, :create ]
  before_action :authorize_bug_creation!, only: [ :new, :create ]

  def index
    @bugs = Bug.includes(:users, project: :assigned_users)
              .order(created_at: :desc)
              .page(params[:page])
              .per(20)
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
    @bugs = current_user
              .bugs
              .order(created_at: :desc)
              .page(params[:page])
              .per(15)
  end

  def import_page
  end

  def import
    file = params[:file]
    unless file && (file.content_type == "text/csv" || File.extname(file.original_filename) == ".csv")
      redirect_to import_bugs_page_path, alert: "Please select a valid CSV file."
      return
    end

    # Create a permanent tmp/uploads directory if it doesn't exist
    uploads_dir = Rails.root.join("tmp", "uploads")
    FileUtils.mkdir_p(uploads_dir) unless Dir.exist?(uploads_dir)

    # Save uploaded file there
    temp_file_path = uploads_dir.join("bug_import_#{SecureRandom.hex(8)}.csv")
    File.open(temp_file_path, "wb") { |f| f.write(file.read) }

    # Pass the file path to Sidekiq Job
    BugImportJob.perform_later(temp_file_path.to_s, current_user.id)

    redirect_to import_bugs_results_path, notice: "CSV import started. Check progress below."
  end

  def import_results
    result_file = Dir.glob(
      Rails.root.join("tmp", "import_bug_result_user_#{current_user.id}*.yml")
    ).max_by { |f| File.mtime(f) }

    @result =
      if result_file && File.exist?(result_file)
        YAML.load_file(result_file).deep_symbolize_keys
      else
        { success_count: 0, failures: [], failed_file: nil, processing: true }
      end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "import_results",
          partial: "shared/import_results",
          locals: { result: @result }
        )
      end
    end
  end

  def import_result_download
    result_file = Dir.glob(
      Rails.root.join("tmp", "import_bug_result_user_#{params[:id]}*.yml")
    ).max_by { |f| File.mtime(f) }

    if result_file && File.exist?(result_file)
      result = YAML.load_file(result_file).deep_symbolize_keys

      if result[:failed_file] && File.exist?(result[:failed_file])
        send_file result[:failed_file],
                  type: "text/csv",
                  filename: "failed_bugs_user_#{params[:id]}.csv",
                  disposition: "attachment"
      else
        redirect_to import_bugs_results_path, alert: "No failed rows CSV found."
      end
    else
      redirect_to import_bugs_results_path, alert: "No import result file found."
    end
  end

  def export
    send_data Bug.to_csv, filename: "bugs-#{Date.today}.csv"
  end

  def project_bugs
    @project = Project.find(params[:project_id])

    unless can_manage_project?(@project)
      redirect_to projects_path, alert: "You are not authorized to view bugs for this project."
      return
    end

    @bugs = @project.bugs
                    .includes(:users)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(20)
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
