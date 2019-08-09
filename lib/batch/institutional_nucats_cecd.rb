# https://github.com/galterlibrary/digital-repository/issues/678
# Create new parent collection 'NUCATS Center for Education and Career Development'
# move NUCATS Grants Repository as child

# NUCATS Grants Repository
parent_nucats_grants = Collection.find("f2bf6e1d-0e32-4ce2-a52e-bb0522d5708d")

admin_group = 'NUCATS-CECD-System-Admin'
depositor = 'institutional-nucats-cecd'

nucats_cecd_sys_user = User.create!(
  username: 'institutional-nucats-cecd-system',
  email: 'institutional-nucats-cecd-system@northwestern.edu',
  display_name: "NUCATS Center for Education and Career Development"
)

role = Role.create!(name: admin_group)

nucats_cecd_col = Collection.new(
  title: 'NUCATS Center for Education and Career Development',
  tag: ["grant proposals", "research support", "peer-reviewed grants"],
  description: 'Funded grant proposals, templates, and stock language for Northwestern investigators'
)
nucats_cecd_col.apply_depositor_metadata(nucats_cecd_sys_user.username)
nucats_cecd_col.members << parent_nucats_grants
nucats_cecd_col.save!

nucats_cecd_col.reload.convert_to_institutional(depositor, nil, admin_group)
