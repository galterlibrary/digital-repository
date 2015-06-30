class Ability
  include Hydra::Ability
  include Sufia::Ability

  # Define any customized permissions here.
  def custom_permissions
    # Editors can do everything but delete things
    if current_user.has_role?('editor')
      can :manage, :all
    end

    if current_user.admin?
      can :manage, :all
    end

    # Limits deleting objects to a the admin user
    if !current_user.admin?
       cannot [:destroy], ActiveFedora::Base
    end
  end
end
