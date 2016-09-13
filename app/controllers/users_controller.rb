class UsersController < ApplicationController
  include Sufia::UsersControllerBehavior
  prepend_before_action :authenticate_user!, only: [
    :new, :create, :edit, :update, :follow, :unfollow, :toggle_trophy
  ]
  authorize_resource only: [:new, :create, :edit, :update, :toggle_trophy]

  def index
    query = params[:uq].blank? ? nil : "%" + params[:uq].downcase + "%"
    base = User.where(*base_query)
    unless query.blank?
      base = base.where(
        "LOWER(username) LIKE ? OR LOWER(display_name) LIKE ? OR LOWER(email) LIKE ?",
        query, query, query
      )
    end
    @users = base.references(:trophies).order(sort_value).page(
      params[:page]).per(10)

    respond_to do |format|
      format.html
      format.json { render json: @users.to_json }
    end
  end

  def new
  end

  def create
    if @user.persisted?
      flash[:notice] = "User #{@user.username} already exists"
      redirect_to(new_user_path)
    else
      create_user_from_ldap
    end
  end

  private

  def create_user_from_ldap
    begin
      @user.populate_attributes
      redirect_to(sufia.profile_path(@user.to_param))
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "Couldn't create user: #{e.cause}"
      redirect_to(new_user_path)
    rescue
      flash[:alert] = "Couldn't create user, username doesn't exist in LDAP?"
      redirect_to(new_user_path)
    end
  end

  def find_user
    if params[:action] == 'new'
      @user = User.new
    elsif params[:action] == 'create'
      @user = User.find_or_initialize_by(username: params[:user][:username])
    else
      super
    end
  end

  def deny_access(_exception)
    redirect_to sufia.profile_path(current_user.to_param), alert: "Permission denied: cannot access this page."
  end

  def sort_value
    val = super
    val == 'login' ? 'username' : val
  end
end
