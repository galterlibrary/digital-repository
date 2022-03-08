class RoleStore
  attr_accessor :data

  def initialize
    @data = Hash.new
  end

  def build_role_store_data
    Role.find_each do |r|
      @data[r.name] = {
        "netids": r.users.map(&:username)
      }
    end
  end
end
