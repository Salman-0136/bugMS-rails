class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :require_login, except: [ :new, :create ]
  before_action :require_admin, only: [ :index, :destroy ]
  before_action :manage_profile_authorization, only: [ :edit, :destroy ]

  # GET /users
  def index
    @users = User.all
  end

  # GET /users/:id
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # POST /users
  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to root_path, notice: "Welcome, #{@user.name}! Your account has been created."
    else
      flash.now[:alert] = "Please fix the errors below."
      render :new, status: :unprocessable_entity
    end
  end

  # GET /users/:id/edit
  def edit
  end

  # PATCH/PUT /users/:id
  def update
    if @user.update(user_params)
      redirect_to @user, notice: "Profile updated successfully."
    else
      flash.now[:alert] = "Please fix the errors below."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: "User deleted successfully."
  end

  def manage_profile_authorization!
    unless can_manage_profile?(@user)
      redirect_back(fallback_location: root_path, alert: "You are not authorized to perform this.")
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :profile_image, :role, is_admin: false)
  end
end
