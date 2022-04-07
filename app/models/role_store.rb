class RoleStore
  attr_accessor :data

  def initialize
    @data = Hash.new
  end

  def build_role_store_data
    Role.find_each do |r|
      @data[r.name] = r.users.pluck(:username, :email).to_h
    end
  end
end
