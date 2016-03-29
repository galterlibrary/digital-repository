module DashboardHelper
  include Sufia::DashboardHelperBehavior

  def on_my_files?
    params[:controller].match(/^my\/(files|shares|highlights)/)
  end
end
