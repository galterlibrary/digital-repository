# Create parent collection 'Covid-19 Community' and 
# institutionalize it.
# https://github.com/galterlibrary/digital-repository/issues/992

admin_group = 'Covid-System-Admin'
depositor = 'institutional-covid'

covid_sys_user = User.create!(
  username: 'institutional-covid-system',
  email: 'institutional-covid-system@northwestern.edu',
  display_name: "Covid-19 Community"
)

role = Role.create!(name: admin_group)

['jbe2215', 'keg827'].each do |contrib|
  u = User.find_or_create_via_username(contrib)
  u.add_role(role.name)
  u.save!
end

covid_col = Collection.new(
  title: 'COVID-19 Community',
  tag: ["COVID-19", "coronavirus", "covid"],
  description: "The COVID-19 Community houses resources on the Coronavirus "\
                "(Covid-19), including clinical reports, management guidelines, "\
                "and commentary authored by Feinberg School of Medicine faculty, "\
                "staff, and students."
)
covid_col.apply_depositor_metadata(
  covid_sys_user.username
)

covid_col.save!
covid_col.reload.convert_to_institutional(depositor, nil, admin_group)
