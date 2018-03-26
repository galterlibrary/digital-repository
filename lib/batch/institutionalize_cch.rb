# Institutionalize Center for Community Health collection 

# cch_col = Collection.find("ae0b945c-d0d4-45bb-a0fc-263c7afca49e")
cch_col = Collection.find("4dafd0db-c4fc-47f3-a5d1-1385d359bdf6")

admin_group = 'CCH-System-Admin'
depositor = 'institutional-cch'


cch_sys = User.create!(
  username: 'institutional-cch-system',
  email: 'institutional-cch-system@northwestern.edu',
  display_name: "Center for Community Health"
)

role = Role.create!(name: admin_group)

# the contributors are the only people who need permissions for this collection
["gmr244", "kah2923"].each do |contrib|
  u = User.where(username: contrib).first
  u.add_role(role.name)
  u.save!
end

cch_col.convert_to_institutional(depositor, nil, admin_group)
