# Institutional Collection: "Communication Bridge"
# https://github.com/galterlibrary/digital-repository/issues/767

admin_group = 'Communication-Bridge-System-Admin'
depositor = 'institutional-communication-bridge'

communication_bridge_sys_user = User.create!(
  username: 'institutional-communication-bridge-system',
  email: 'institutional-communication-bridge-system@northwestern.edu',
  display_name: "Communication Bridge"
)

role = Role.create!(name: admin_group)

['ear1473', 'ejr315'].each do |contrib|
  u = User.find_or_create_via_username(contrib)
  u.add_role(role.name)
  u.save!
end

communication_bridge_collection = Collection.new(
  title: 'Communication Bridge',
  tag: ["Alzheimer’s Disease", "Cognitive Neurology"]
)

communication_bridge_collection.apply_depositor_metadata(
  communication_bridge_sys_user.username
)

communication_bridge_collection.save!
communication_bridge_collection.reload.convert_to_institutional(depositor, nil, admin_group)
