require 'csv'

class UsersList
  attr_accessor :csv_file

  def initialize
    @csv_file = File.new("#{Rails.root}/lib/scripts/results/users_list.csv", "w+")
  end

  def populate_user_info
    CSV.open(self.csv_file.path, "w") do |csv|
      # add headers
      csv << ['Formal Name', 'NetID', 'Email', 'Current Sign In', 'Last Sign In']

      select_all_users.find_in_batches do |users_batch|
        users_batch.each do |user|
          csv << [user.formal_name, user.username, user.email,
                  user.current_sign_in_at, user.last_sign_in_at]
        end
      end
    end # end block, CSV closes
  end

  private
  def select_all_users
    User.all.select(:id, :formal_name, :username, :email,
                    :current_sign_in_at, :last_sign_in_at)
  end
end