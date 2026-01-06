# app/controllers/users/registrations_controller.rb
module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    # Allow updating profile without password
    def update_resource(resource, params)
      if params[:password].blank? && params[:current_password].blank?
        params.delete(:password)
        params.delete(:password_confirmation)
        params.delete(:current_password)
        resource.update_without_password(params)
      else
        super
      end
    end
  end
end
