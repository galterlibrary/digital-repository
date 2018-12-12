# Create parent collection 'NUCATS Grants Repository' and institutionalize it
# Create subcollections: R01, R03, R21, K-Series and add to parent collection

admin_group = 'NUCATS-Grants-Repository-System-Admin'
depositor = 'institutional-nucats-grants-repository'

nucats_grants_sys_user = User.create!(
  username: 'institutional-nucats-grants-repository-system',
  email: 'institutional-nucats-grants-repository-system@northwestern.edu',
  display_name: "NUCATS Grants Repository"
)

role = Role.create!(name: admin_group)

['kah2923', 'ejt0440', 'jcz828'].each do |contrib|
  u = User.find_or_create_via_username(contrib)
  u.add_role(role.name)
  u.save!
end

nucats_grants_col = Collection.new(
  title: 'NUCATS Grants Repository',
  tag: ["grant proposals", "research support", "peer-reviewed grants"],
  description: 'Funded grant proposals, templates, and stock language for Northwestern investigators'
)
nucats_grants_col.apply_depositor_metadata(nucats_grants_sys_user.username)

['R01', 'R03', 'R21', 'K-series'].each do |child|
  col = Collection.new(
    title: child,
    tag: ["grant proposals", "research support", "peer-reviewed grants"]
  )
  col.apply_depositor_metadata(nucats_grants_sys_user.username)
  col.save!

  nucats_grants_col.members << col
end

nucats_grants_col.save!
nucats_grants_col.reload.convert_to_institutional(depositor, nil, admin_group)

