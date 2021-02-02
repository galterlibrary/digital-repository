# Create parent collection 'Northwestern Pepper Center' and
# institutionalize it, and create subcollections
# https://github.com/galterlibrary/digital-repository/issues/818

admin_group = 'Northwestern-Pepper-Center-System-Admin'
depositor = 'institutional-northwestern-pepper-center'

northwestern_pepper_center_sys_user = User.create!(
  username: 'institutional-northwestern-pepper-center-system',
  email: 'institutional-northwestern-pepper-center-system@northwestern.edu',
  display_name: "Northwestern Pepper Center"
)

role = Role.create!(name: admin_group)

['jnb235', 'gas162', 'ers050', 'lah315'].each do |contrib|
  u = User.find_or_create_via_username(contrib)
  u.add_role(role.name)
  u.save!
end

northwestern_pepper_center_col = Collection.new(
  title: 'Northwestern Pepper Center',
  tag: ["aging research", "multiple chronic conditions", "geriatrics", "primary care"],
  description: "The mission of the Northwestern Pepper Center is to generate "\
               "innovative research that will enhance primary care for "\
               "medically complex, older adults with multiple chronic "\
               "conditions to achieve optimal health, function, independence "\
               "and quality of life."
)
northwestern_pepper_center_col.apply_depositor_metadata(
  northwestern_pepper_center_sys_user.username
)

northwestern_pepper_center_col.save!
northwestern_pepper_center_col.reload.convert_to_institutional(depositor, nil, admin_group)
