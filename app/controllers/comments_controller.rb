class CommentsController < ApplicationController
  before_action :set_comment, only: [ :show, :edit, :update, :destroy ]

  def index
    @comments = Comment.all
  end

  def show
  end

  def new
    @comment = Comment.new
  end

  def create
    @comment = Comment.new(comment_params)
    if @comment.save
      redirect_to bug_path(@comment.bug), notice: "Comment was successfully created."
    else
      render :new
    end
  end

  def destroy
    @comment.destroy
    redirect_to bug_url(@comment.bug), notice: "Comment was successfully destroyed."
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end
  def comment_params
    params.require(:comment).permit(:content, :bug_id, :user_id, attachments: [])
  end
end
