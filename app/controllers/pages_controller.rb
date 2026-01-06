class PagesController < ApplicationController
  before_action :authenticate_user!, only: [ :home ]
  def home
    @bugs = Bug
      .includes(:users)
      .order(created_at: :desc)
      .limit(10)
  end

  def about
  end

  def contact
  end
end
