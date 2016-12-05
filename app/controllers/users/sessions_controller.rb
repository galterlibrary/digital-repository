class Users::SessionsController < Devise::SessionsController
  prepend_before_action :store_previous_location, only: [:new]

  def store_previous_location
    store_location_for(scope_name, request.referrer)
  end
  private :store_previous_location

  def new
    if ENV['SHIBBOLETH_AUTH'] == 'true'
      flash.alert = nil
      redirect_to user_omniauth_authorize_path(:shibboleth)
    else
      super
    end
  end
end
