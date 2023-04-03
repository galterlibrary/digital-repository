class User < ActiveRecord::Base
  validates :username,
    :presence => true,
    :uniqueness => { :case_sensitive => false }

  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles
  # Connects this user object to Sufia behaviors.
  include Sufia::User
  include Sufia::UserUsageStats

  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :ldap_authenticatable, :rememberable, :trackable,
         :omniauth_providers => [:shibboleth]

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    login
  end

  def has_role?(role)
    roles.where(name: role).exists?
  end
  alias_method :in_group?, :has_role?

  def sunset_editor?
    has_role?("sunset-editor")
  end

  def add_to_group(name)
    return roles if has_role?(name)
    roles << Role.find_by(name: name)
  end
  alias_method :add_role, :add_to_group

  def remove_from_group(name)
    return roles unless has_role?(name)
    roles.delete(Role.find_by(name: name))
  end
  alias_method :remove_role, :remove_from_group

  def is_admin?
    (groups & ['admin', 'editor']).present?
  end

  def groups
    all_groups = roles.map do |role|
      role.name
    end

    if username.present? && username != 'guest'
      all_groups + ['registered']
    else
      all_groups
    end
  end

  def populate_attributes
    ldap_working, results = Nuldap.new.search("uid=#{user_key}")
    unless ldap_working
      Rails.logger.warn "No ldapresults exists for #{user_key}"
      return
    end

    raise 'Empty LDAP response' if results.empty?
    attrs = {}
    attrs[:email] = results['mail'].first rescue nil
    attrs[:display_name] = results['displayName'].first rescue nil
    attrs[:formal_name] = Nuldap.standardized_name(results)
    attrs[:address] = results['postalAddress'].first.gsub('$', "\n") rescue nil
    attrs[:title] = results['title'].first rescue nil
    attrs[:chat_id] = results['pschatname'].first rescue nil
    attrs[:orcid] = results['eduPersonOrcid'].first rescue nil
    update_attributes!(attrs)
  end

  def nuldap_groups
    ldap_working, results = Nuldap.new.search("uid=#{user_key}")
    if ldap_working && results.try(:[], 'ou').present?
      results['ou'].reject {|o| o == 'People' }
    else
      Rails.logger.warn "No ldapresults exists for #{user_key}"
      []
    end
  end

  def login=(login)
    @login = login
  end

  def login
    @login || self.username
  end

  def [](key)
    key == :login ? login : super
  end

  def normalize_name(role_name)
    role_name.gsub(/[^a-zA-Z_.-]/, '-')
             .gsub(/-+/, '-')
             .gsub(/^-+/, '')
             .gsub(/-+$/, '')
  end
  private :normalize_name

  def normalize_orcid
    # Override the upstream implementation with secure url
    # and more normalization handling
    return if errors[:orcid].first.present? || orcid.blank?
    bare_orcid = Sufia::OrcidValidator.match(orcid).try(:[], 0)
    self.orcid = "https://orcid.org/#{bare_orcid}"
  end
  private :normalize_orcid

  def add_to_nuldap_groups
    nuldap_groups.each do |ldap_role_name|
      formatted_name = normalize_name(ldap_role_name)
      unless Role.find_by(name: formatted_name)
        Role.create(name: formatted_name, description: ldap_role_name)
      end
      add_role(formatted_name)
    end
  end

  def name
    if caller.grep(/actor.rb/).present? ||
        caller.grep(/batch_controller_behavior.*edit_form/).present?
      return formal_name
    end
    super
  end

  # Hacks for collection followers
  def all_following
    super.compact
  end
  # Hacks for collection followers ends

  def all_followed_collections
    Follow.where(
      followable_type: 'Collection',
      follower_id: self.id,
      follower_type: 'User'
    ).pluck(:followable_fedora_id).map {|cid|
      col_solr = ActiveFedora::SolrService.query("id:#{cid}").first
      next unless col_solr.present?
      { title: col_solr['title_tesim'].first,
        id: cid }
    }.compact.sort_by {|o| o['title'] }
  end

  class << self
    def find_or_create_via_username(username)
      unless user = User.find_by(username: username)
        user = User.new(username: username)
        user.populate_attributes
        user.add_to_nuldap_groups
      end
      user
    end

    def find_for_ldap_authentication(attributes={})
      return nil unless attributes[:login].present?
      auth_key_value = attributes[:login].strip.downcase
      resource = find_or_initialize_by(username: auth_key_value)

      if ::Devise.ldap_create_user && resource.new_record? &&
          resource.valid_ldap_authentication?(attributes[:password])
        resource.ldap_before_save if resource.respond_to?(:ldap_before_save)
        resource.populate_attributes
        resource.add_to_nuldap_groups
      end

      resource
    end

    def find_by_login(login)
      User.where(
        "lower(username) = :value OR lower(email) = :value",
        { :value => login.downcase }
      ).first
    end
    alias_method :find_by_user_key, :find_by_login

    def audituser
      User.find_by_user_key(audituser_key) || User.create!(
        username: audituser_key)
    end

    def audituser_key
      'audituser'
    end

    def batchuser
      User.find_by_user_key(batchuser_key) || User.create!(
        username: batchuser_key)
    end

    def batchuser_key
      'batchuser'
    end
  end
end
