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
  devise :ldap_authenticatable, :rememberable, :trackable

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

  def add_to_group(name)
    return roles if has_role?(name)
    roles << Role.find_by(name: name)
  end
  alias_method :add_role, :add_to_group

  def groups
    roles.map(&:name)
  end

  def populate_attributes
    ldap_working, results = Nuldap.new.search("uid=#{user_key}")
    unless ldap_working
      Rails.logger.warn "No ldapresults exists for #{user_key}"
      return
    end

    return if results.empty?
    attrs = {}
    attrs[:email] = results['mail'].first rescue nil
    attrs[:display_name] = results['displayName'].first rescue nil
    attrs[:address] = results['postalAddress'].first.gsub('$', "\n") rescue nil
    #attrs[:department] = results[:psdepartment].first rescue nil
    attrs[:title] = results['title'].first rescue nil
    attrs[:chat_id] = results['pschatname'].first rescue nil
    update_attributes!(attrs)
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

  class << self
    def find_for_ldap_authentication(attributes={})
      return nil unless attributes[:login].present?
      auth_key_value = attributes[:login].strip.downcase
      resource = find_by(username: auth_key_value)

      if resource.blank?
        resource = User.new(username: auth_key_value)
      end

      if ::Devise.ldap_create_user && resource.new_record? &&
          resource.valid_ldap_authentication?(attributes[:password])
        resource.ldap_before_save if resource.respond_to?(:ldap_before_save)
        resource.save!
        resource.populate_attributes
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
