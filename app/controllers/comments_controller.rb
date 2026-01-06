class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: [ :show, :destroy ]
  before_action :set_bug_for_create, only: [ :create ]

  # Load and authorize resource automatically using CanCanCan
  # You can also use `load_and_authorize_resource` if you prefer
  # but here we'll manually authorize for more control

  def index
    # Only show comments user can read
    @comments = Comment.accessible_by(current_ability)
  end

  def show
    authorize! :read, @comment
  end

  def new
    @comment = Comment.new
  end

  def create
    @bug = Bug.find(params[:comment][:bug_id])

    @comment = @bug.comments.build(comment_params)
    @comment.user = current_user

    authorize! :create, @comment

    if @comment.save
      redirect_to bug_path(@bug), notice: "Comment successfully created."
    else
      redirect_to bug_path(@bug),
                  alert: @comment.errors.full_messages.to_sentence,
                  status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @comment # CanCanCan authorization

    @bug = @comment.bug
    @comment.destroy
    redirect_to bug_path(@bug), notice: "Comment was successfully destroyed."
  end

  private

  # Load the comment
  def set_comment
    @comment = Comment.find(params[:id])
  end

  # Load the bug before creating a comment
  def set_bug_for_create
    @bug = Bug.find(params[:comment][:bug_id])
  end

  def comment_params
    params.require(:comment).permit(:content, attachments: [])
  end
end
