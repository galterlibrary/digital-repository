# Institutionalize NUCATS Series on Developing and Enhancing Mentoring Relationships collection

demr_col = Collection.find("98aba013-3005-4cbe-9fb0-e21960a8e274")

admin_group = 'DEMR-System-Admin'
depositor = 'institutional-demr'

demr_sys = User.create!(
  username: 'institutional-demr-system',
  email: 'institutional-demr-system@northwestern.edu',
  display_name: "NUCATS Series on Developing and Enhancing Mentoring Relationships"
)

role = Role.create!(name: admin_group)

# the contributors are the only people who need permissions for this collection
["crc7287"].each do |contrib|
  u = User.where(username: contrib).first
  u.add_role(role.name)
  u.save!
end

demr_col.convert_to_institutional(depositor, nil, admin_group)
