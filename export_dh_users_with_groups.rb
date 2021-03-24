file_name = "dh_users_with_groups.csv"

CSV.open(file_name, "w") do |csv|
  headers = ["Owner Net Id", "Owner Email", "Owner Fullname", "Owner Groups"]
  csv << headers

  User.all.each do |user|
    csv << [user.username, user.email, user.name, user.groups]
  end
end
