class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  helper_method :current_user, :logged_in?, :can_manage_bug?, :can_manage_project?, :delete_project?, :can_manage_profile?

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "You must be logged in to access this section."
    end
  end

  def require_admin
    unless logged_in? && current_user.is_admin?
      redirect_to root_path, alert: "You must be an admin to access this section."
    end
  end

  def can_manage_bug?(bug)
    return false unless current_user
    is_manager = bug.project && current_user.id == bug.project.manager_id
    is_assigned = bug.project.assigned_users.include?(current_user)

    is_manager || is_assigned
  end

  def can_manage_project?(project)
    return false unless current_user
      is_manager = project && current_user.id == project.manager_id
      is_assigned = project.assigned_users.include?(current_user)

      is_manager || is_assigned
  end

  def delete_project?(project)
    return false unless current_user
      is_manager = project && current_user.id == project.manager_id
      is_manager
  end

  def can_manage_profile?(user)
    return false unless current_user
      is_user = logged_in? && user.id == current_user.id
      is_admin = logged_in? && current_user.is_admin
      is_user || is_admin
  end

  allow_browser versions: :modern
end
