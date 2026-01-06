class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :destroy ]
  before_action :authenticate_user!
  load_and_authorize_resource

  # GET /users
  def index
    authorize! :read, User
    @users = User.all
                  .page(params[:page])
                  .per(9)
  end

  # GET /users/:id
  def show
    @bugs = Bug
      .includes(:users)
      .order(created_at: :desc)
      .page(params[:page])
      .per(10)

     @reset_link = edit_password_url(@user, reset_password_token: @user.send_reset_password_instructions)
  end

  def destroy
    authorize! :destroy, @user
    @user.destroy
    redirect_to users_path, notice: "User deleted successfully."
  end

  def send_reset
    @user = User.find(params[:id])
    authorize! :send_reset, @user

    @user.send_reset_password_instructions

    redirect_to @user, notice: "Password reset email sent successfully."
  end

  def admin_dashboard
    authorize! :manage, User

    @users = User
      .select(:id, :name, :email, :role,
              :sign_in_count, :current_sign_in_at,
              :last_sign_in_at, :current_sign_in_ip,
              :last_sign_in_ip)
      .where.not(is_admin: true)
      .order(:id)
      .page(params[:page])
      .per(10)

    # Dashboard counts
    @total_users    = User.where(is_admin: false).count
    @total_projects = Project.count
    @total_bugs     = Bug.count

    # Charts (last 12 months)
    @users_chart    = User.group_by_month(:created_at, last: 12).count
    @projects_chart = Project.group_by_month(:created_at, last: 12).count
    @bugs_chart     = Bug.group_by_month(:created_at, last: 12).count
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :profile_image, :role, is_admin: false)
  end
end
