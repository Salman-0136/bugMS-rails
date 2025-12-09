class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_comment, only: [ :show, :destroy ]
  before_action :set_bug_for_create, only: [ :create ]
  before_action :authorize_comment!, only: [ :create, :destroy ]

  def index
    @comments = Comment.all
  end

  def show
  end

  def new
    @comment = Comment.new
  end

  def create
    @comment = @bug.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to bug_path(@bug), notice: "Comment successfully created."
    else
      flash[:alert] = "Failed to post comment: " + @comment.errors.full_messages.join(", ")
      redirect_to bug_path(@bug), status: :unprocessable_entity
    end
  end

  def destroy
    @bug = @comment.bug
    @comment.destroy
    redirect_to bug_path(@bug), notice: "Comment was successfully destroyed."
  end

  private

  # Load the comment
  def set_comment
    @comment = Comment.find(params[:id])
  end

  # Load the bug before create
  def set_bug_for_create
    @bug = Bug.find(params[:comment][:bug_id])
  end

  # Authorize user for the bug
  def authorize_comment!
    bug = @bug || @comment.bug
    unless can_manage_bug?(bug)
      redirect_to bug_path(bug), alert: "You are not authorized to perform this action."
    end
  end

  def comment_params
    params.require(:comment).permit(:content, attachments: [])
  end
end
