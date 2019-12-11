# Create parent collection 'Center for Data Science and Informatics' and 
# institutionalize it, and create subcollections
# https://github.com/galterlibrary/digital-repository/issues/703

admin_group = 'Center-for-Data-Science-and-Informatics-System-Admin'
depositor = 'institutional-center-for-data-science-and-informatics'

center_for_data_science_and_informatics_sys_user = User.create!(
  username: 'institutional-center-for-data-science-and-informatics-system',
  email: 'institutional-center-for-data-science-and-informatics-system@northwestern.edu',
  display_name: "Center for Data Science and Informatics"
)

role = Role.create!(name: admin_group)

['jbs642', 'aco454', 'nds616'].each do |contrib|
  u = User.find_or_create_via_username(contrib)
  u.add_role(role.name)
  u.save!
end

center_for_data_science_and_informatics_col = Collection.new(
  title: 'Center for Data Science and Informatics',
  tag: ["data science", "informatics", "NUCATS", "CDSI"],
  description: "The Center for Data Science and Informatics (CDSI) works to "\
                "advance the applications of data science and informatics "\
                "toward improved biomedical research and healthcare at NUCATS "\
                "and with clinical partners. The CDSI vision is to create an "\
                "integrated healthcare and research environment in which all "\
                "available data are optimally leveraged for knowledge "\
                "discovery and improved health."
)
center_for_data_science_and_informatics_col.apply_depositor_metadata(
  center_for_data_science_and_informatics_sys_user.username
)

center_for_data_science_and_informatics_col.save!
center_for_data_science_and_informatics_col.reload.convert_to_institutional(depositor, nil, admin_group)
