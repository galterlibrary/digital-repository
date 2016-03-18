class Users::SessionsController < Devise::SessionsController
  def new
    if Rails.env.staging? || Rails.env.production?
      flash.alert = nil
      redirect_to user_omniauth_authorize_path(:shibboleth)
    else
      super
    end
  end
end
