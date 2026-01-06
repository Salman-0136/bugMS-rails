class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  include CanCan::ControllerAdditions

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: "You are not authorized to access this page."
  end

  allow_browser versions: :modern

  protected

  def configure_permitted_parameters
    # Permit :name for sign_up and account_update
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
