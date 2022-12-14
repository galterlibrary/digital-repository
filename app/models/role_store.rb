class RoleStore
  attr_accessor :data

  def initialize
    @data = Hash.new
  end

  def build_role_store_data
    josh_elder_username = "jbe2215"
    josh_elder_email  = "JoshElder@northwestern.edu"

    Role.find_each do |role|
      role_user_data = r.users.pluck(:username, :email).to_h

      # update Josh's email to titlecase in the role store
      if role_user_data[josh_elder_username]
        role_user_data[josh_elder_username] = josh_elder_email
      end

      @data[role.name] = role_user_data
    end
  end
end
