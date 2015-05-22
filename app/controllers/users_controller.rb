class UsersController < ApplicationController
  include Sufia::UsersControllerBehavior

  def index
    sort_val = get_sort
    query = params[:uq].blank? ? nil : "%"+params[:uq].downcase+"%"
    base = User.where(*base_query)
    unless query.blank?
      base = base.where(
        "username like lower(?) OR display_name like lower(?) OR email like lower(?)", query, query, query)
    end
    @users = base.references(:trophies).order(sort_val).page(
      params[:page]).per(10)

    respond_to do |format|
      format.html
      format.json { render json: @users.to_json }
    end
  end
end
