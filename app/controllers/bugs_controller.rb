class BugsController < ApplicationController
  before_action :set_bug, only: [ :show, :edit, :update, :destroy ]

  def index
    @bugs = Bug.all.order(created_at: :desc)
  end

  def show
  end
  
  def new
    @bug = Bug.new
  end

  def create
    @bug = Bug.new(bug_params)
    if @bug.save
      redirect_to @bug, notice: "Bug was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @bug.update(bug_params)
      redirect_to @bug, notice: "Bug was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @bug.destroy
    redirect_to bugs_url, notice: "Bug was successfully destroyed."
  end

  # def my_bugs
  #   @bugs = current_user.bugs.order(created_at: :desc)
  # end

  private

  def bug_params
    params.require(:bug).permit(:title, :description, :status, :priority, :severity, :bug_type, :due_date, user_ids: [])
  end

  def set_bug
    @bug = Bug.find(params[:id])
  end
end
