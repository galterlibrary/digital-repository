class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def shibboleth
    @auth = request.env['omniauth.auth']
    Rails.logger.info("SHIB: #{@auth.inspect}")
    user = @current_user
    if user.blank?
      uid, is_nu_user = verify_northwestern_user
      user = User.find_or_create_via_username(uid)
    end
    redirect_user(user, is_nu_user)
  end

  private

  def redirect_user(user, is_nu_user)
    if is_nu_user
      sign_in_and_redirect user, :event => :authentication
    else
      flash[:alert] = "Only Northwestern University affiliates can log in."
      redirect_to '/'
    end
  end

  def verify_northwestern_user
    uid, domain = @auth.uid.to_s.split('@').map(&:downcase)
    [uid, (domain == 'northwestern.edu' || domain.nil?)]
  end
end
