Warden::Manager.after_set_user(:except => :fetch) do |user, auth, opts|
  user.populate_attributes
end
