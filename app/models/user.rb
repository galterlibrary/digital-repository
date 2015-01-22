class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors. 
  include Hydra::User# Connects this user object to Sufia behaviors.
  include Sufia::User
  include Sufia::UserUsageStats

  # Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :user_roles
  has_many :roles, through: :user_roles

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def populate_attributes
    #FIXME use uid to search
    ldap_working, results = Nuldap.new.search("mail=#{user_key}")
    unless ldap_working
      Rails.logger.warn "No ldapresults exists for #{user_key}"
      return
    end

    attrs = {}
    #attrs[:email] = results[:mail].first rescue nil
    attrs[:display_name] = results['displayName'].first rescue nil
    attrs[:address] = results['postalAddress'].first.gsub('$', "\n") rescue nil
    #attrs[:department] = results[:psdepartment].first rescue nil
    attrs[:title] = results['title'].first rescue nil
    attrs[:chat_id] = results[:pschatname].first rescue nil
    update_attributes!(attrs)
  end

  def has_role?(role)
    roles.where(role: role).present?
  end

  def admin?
    has_role?('admin')
  end

  def add_role(role)
    return if has_role?(role)
    roles << Role.find_by(role: role)
  end
end
