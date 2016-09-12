class UsersController < ApplicationController
  include Sufia::UsersControllerBehavior

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

  private

  def sort_value
    val = super
    val == 'login' ? 'username' : val
  end
end
