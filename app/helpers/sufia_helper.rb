module SufiaHelper
  include ::BlacklightHelper
  include Sufia::BlacklightOverride
  include Sufia::SufiaHelperBehavior

  def user_groups
    current_user.roles.map {|o| [(o.description or o.name), o.name] }
  end
end
