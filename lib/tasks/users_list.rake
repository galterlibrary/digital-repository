require "#{Rails.root}/lib/scripts/users_list"

namespace :users_list do
  desc "Get list of users and their info in csv"
  task export_users_list: :environment do
    @users_list = UsersList.new

    @users_list.populate_user_info

    puts "Export complete, check 'lib/scripts/results/' for csv file"
  end
end
