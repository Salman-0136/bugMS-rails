class SearchController < ApplicationController
  before_action :require_login
  def index
    @query = params[:q]

    # Users
    @users = User.where("name ILIKE ?", "%#{@query}%") if @query.present?

    # Projects
    @projects = Project.where("name ILIKE ?", "%#{@query}%") if @query.present?

    # Bugs
    @bugs = Bug.where("title ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%") if @query.present?

    # Comments
    @comments = Comment.where("content ILIKE ?", "%#{@query}%") if @query.present?
  end
end
