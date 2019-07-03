# Create parent collection 'Department of Psychiatry and Behavioral Sciences 
# Collection' and institutionalize it
# Create subcollections and add to parent collection:
# - Department Events
#   - Conferences
#   - Commencement
#   - Grand Rounds
#   - Scholars Day
# - Newsletters

admin_group = 'Department-of-Psychiatry-and-Behavioral-Sciences-System-Admin'
depositor = 'institutional-department-of-psychiatry-and-behavioral-sciences'

dept_of_psych_and_behavioral_sci_sys_user = User.create!(
  username: 'institutional-department-of-psychiatry-and-behavioral-sciences-system',
  email: 'institutional-department-of-psychiatry-and-behavioral-sciences-system@northwestern.edu',
  display_name: "Department of Psychiatry and Behavioral Sciences"
)

role = Role.create!(name: admin_group)

collection_user = User.find_or_create_via_username("rrr998")
collection_user.add_role(role.name)
collection_user.save!

tags = ["psychiatry", "psychology", "psych", "brain", "addiction",
        "neuromodulation", "neuropsychology", "forensic psychiatry",
        "consultation-liaison psychiatry", "geriatric psychiatry",
        "behavioral health", "women's behavioral health",
        "psychiatric education"]

# The parent collection
dept_of_psych_and_behavioral_sci_col = Collection.new(
  title: 'Department of Psychiatry and Behavioral Sciences Collection',
  tag: tags,
  description: "A digital collection of information from the Department of Psychiatry and Behavioral Sciences"
)
dept_of_psych_and_behavioral_sci_col.apply_depositor_metadata(
  dept_of_psych_and_behavioral_sci_sys_user.username
)

# child sub collection one
dept_events = Collection.new(
  title: 'Department Events',
  tag: tags
)
dept_events.apply_depositor_metadata(
  dept_of_psych_and_behavioral_sci_sys_user.username
)

# "grandchildren" of sub collection one
["Conferences", "Commencement", "Grand Rounds", "Scholars Day"].each do |child|
  col = Collection.new(
    title: child,
    tag: tags
  )
  col.apply_depositor_metadata(
    dept_of_psych_and_behavioral_sci_sys_user.username
  )
  col.save!

  dept_events.members << col
end

dept_events.save!

# child sub collection two
newsletters = Collection.new(
  title: 'Newsletters',
  tag: tags,
  description: "Newsletters from the Department of Psychiatry and Behavioral Sciences"
)
newsletters.apply_depositor_metadata(
  dept_of_psych_and_behavioral_sci_sys_user.username
)
newsletters.save!

# add sub collections to parent and convert to institutional
dept_of_psych_and_behavioral_sci_col.members << dept_events 
dept_of_psych_and_behavioral_sci_col.members << newsletters
dept_of_psych_and_behavioral_sci_col.save! 

dept_of_psych_and_behavioral_sci_col.reload.convert_to_institutional(
  depositor, nil, admin_group
)
