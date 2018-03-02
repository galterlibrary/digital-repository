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

    def get_solr_doc(object_id)
      resp = ActiveFedora::SolrService.instance.conn.get(
        'select', params: { q: "id:#{object_id}" })
      if resp['response']['numFound'] == 0
        raise Blacklight::Exceptions::InvalidSolrID.new(
           "Parent collection: #{object_id} was not found")
      end
      resp['response']['docs'].first
    end

    def is_institutional?(object_id)
      get_solr_doc(object_id)['institutional_collection_bsi']
    end

    can [:remove_members], Array do |member_ids|
      can_remove = true
      member_ids.each do |id|
        next unless is_institutional?(id)
        can_remove = false
      end
      can_remove
    end

    can [:add_members], Collection do |collection|
      test_edit(collection.id)
    end

    can [:add_members], String do |collection_id|
      test_edit(collection_id)
    end

    can [:follow, :unfollow], Collection do |collection|
      test_read(collection.id)
    end

    can [:follow, :unfollow], String do |collection_id|
      test_read(collection_id)
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
