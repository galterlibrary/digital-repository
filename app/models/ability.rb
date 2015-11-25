class Ability
  include Hydra::Ability
  include Sufia::Ability

  # Define any customized permissions here.
  def custom_permissions
    def is_institutional_group_admin?(object)
      common_groups = object.edit_groups & current_user.groups
      common_groups.any? {|o| o.include?('-Admin') } ? true : false
    end

    cannot [:edit, :update, :new, :create], Collection do |collection|
      !is_institutional_group_admin?(collection) if collection.is_institutional?
    end

    can [:add_members], Collection do |collection|
      test_edit(collection.id)
    end

    # Editors can do everything but delete things
    if current_user.has_role?('editor')
      can :manage, :all
    end

    if current_user.admin?
      can :manage, :all
    end

    # Limits deleting objects to a the admin user
    if !current_user.admin?
       cannot [:destroy], :all
    end

  end
end
