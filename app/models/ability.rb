# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user

    # Admin can do everything
    if user.is_admin?
      can :manage, :all
      can :read, User
      can :import, :Bugs
      can :import, :Projects
      can :export, :Bugs
      can :export, :Projects
      return
    end

    # ----------------------------
    # Projects
    # ----------------------------
    can :read, Project
    can [ :update, :destroy ], Project, manager_id: user.id
    # Only Managers can manage their projects
    can :manage, Project do |project|
      project.manager_id == user.id
    end
    can :view_bugs, Project do |project|
      project.assigned_user_ids.include?(user.id) || project.manager_id == user.id
    end

    # ----------------------------
    # Bugs
    # ---------------------------
    # Users can view bugs of projects they are assigned to or manage
    can :read, Bug do |bug|
      bug.project.present? &&
      (bug.project.assigned_user_ids.include?(user.id) || bug.project.manager_id == user.id || bug.users.include?(user))
    end

    # Users can create bugs in projects they are assigned to or manage
    can :create, Bug do |bug|
      project = bug.project || Project.find_by(id: bug.project_id)
      project && (project.assigned_user_ids.include?(user.id) || project.manager_id == user.id)
    end

    # Users can update bugs they are assigned to, or in their project
    can :update, Bug do |bug|
      bug.project.present? &&
      (bug.project.assigned_user_ids.include?(user.id) || bug.project.manager_id == user.id || bug.users.include?(user))
    end

    # Only Managers can destroy bugs
    can :destroy, Bug do |bug|
      bug.project.present? && bug.project.manager_id == user.id
    end

    # ----------------------------
    # Comments
    # ----------------------------
    can :manage, Comment do |comment|
      comment.bug.present? &&
      (comment.bug.project.assigned_user_ids.include?(user.id) || comment.bug.project.manager_id == user.id || comment.bug.users.include?(user))
    end

    # ----------------------------
    # Users
    # ----------------------------
    cannot :read, User
    can [ :update, :destroy, :show, :send_reset ], User, id: user.id # can edit their own profile
  end
end
