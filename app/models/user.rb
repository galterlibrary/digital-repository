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
