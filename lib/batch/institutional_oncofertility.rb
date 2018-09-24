# Create Collection "Dialogues in Oncofertility" and institutionalize it.

admin_group = 'Dialogues-in-Oncofertility-System-Admin'
depositor = 'institutional-dialogues-in-oncofertility'

oncofertility_sys_user = User.create!(
  username: 'institutional-dialogues-in-oncofertility-system',
  email: 'institutional-dialogues-in-oncofertility-system@northwestern.edu',
  display_name: "Oncofertility Consortium"
)

role = Role.create!(name: admin_group)

u = User.find_or_create_via_username("lma467")
u.add_role(role.name)
u.save!

oncofertility_col = Collection.new(
  title: 'Dialogues in Oncofertility',
  tag: ["Dialogues in Oncofertility"]
)

oncofertility_col.apply_depositor_metadata('institutional-dialogues-in-oncofertility-system')
oncofertility_col.save!

oncofertility_col.reload.convert_to_institutional(depositor, nil, admin_group)

