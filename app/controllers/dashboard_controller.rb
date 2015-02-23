class DashboardController < ApplicationController
  include Sufia::DashboardControllerBehavior
  protected

  def gather_dashboard_information_bad
    @user = current_user
    @activity = current_user.get_all_user_activity(params[:since].blank? ? DateTime.now.to_i - Sufia.config.activity_to_show_default_seconds_since_now : params[:since].to_i)
    @notifications = current_user.mailbox.inbox
    @incoming = ProxyDepositRequest.where(receiving_user_id: current_user.id).reject &:deleted_file?
    @outgoing = ProxyDepositRequest.where(sending_user_id: current_user.id)
  end
end
