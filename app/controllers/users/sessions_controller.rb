class Users::SessionsController < Devise::SessionsController
  def new
    if ENV['SHIBBOLETH_AUTH'] == 'true'
      flash.alert = nil
      redirect_to user_omniauth_authorize_path(:shibboleth)
    else
      super
    end
  end
end
