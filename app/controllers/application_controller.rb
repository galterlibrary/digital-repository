class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :antispam_timestamp
  after_action :no_bot_crawl_on_staging
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Adds Sufia behaviors into the application controller
  include Sufia::Controller
  include Hydra::Controller::ControllerBehavior

  layout 'sufia-one-column'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  config.antispam_threshold = 5
  def antispam_timestamp
    session['antispam_timestamp'] ||= Time.now
  end

  def no_bot_crawl_on_staging
    if Rails.env.staging?
      response.headers['X-Robots-Tag'] = 'noindex'
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    if ENV['SHIBBOLETH_AUTH'] == 'true'
      ENV['SSO_SIGN_OUT_URL']
    else
      super
    end
  end

  def stored_or_location(resource)
    stored = stored_location_for(resource)
    if stored.blank?
      sufia.dashboard_index_path
    else
      stored == root_path ? sufia.dashboard_index_path : stored
    end
  end

  def after_sign_in_path_for(resource)
    request.env['user_return_to'] || stored_or_location(resource)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) {|u|
      u.permit(:username, :email, :password, :password_confirmation,
               :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) {|u|
      u.permit(:login, :username, :email, :password, :remember_me) }
  end

  #around_filter :profile if Rails.env == 'development'
  def profile
    if params[:profile] && result = RubyProf.profile { yield }

      out = StringIO.new
      RubyProf::GraphHtmlPrinter.new(result).print out, :min_percent => 0
      self.response_body = out.string

    else
      yield
    end
  end
end
