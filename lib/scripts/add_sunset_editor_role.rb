#!/usr/bin/env ruby
# Checks the error rate of paths created based on a GenericFile's checksum.
# To run from the base directory of this app:
# `$ b rails r lib/scripts/add_sunset_editor_role.rb`

# Create new role
sunset_editor = Role.create(name: "sunset-editor", description: "Allow user to edit files after DigitalHub is closed to the public")

# Find and assign users to role
user_emails = ["gretchen.neidhardt@northwestern.edu", "eric.newman@northwestern.edu"]
users = User.where(email: user_emails)

users.each do |user|
  user.roles << sunset_editor
end
