# Create collection "Students' Collection"
# Add "Masters in Public Health CE Papers" collection to "Students' Collection"
# Convert "Students' Collection" to institutional collection

admin_group = 'Students-System-Admin'
depositor = 'institutional-students'

students_sys = User.create(
  username: 'institutional-students-system',
  email: 'institutional-students-system@northwestern.edu',
  display_name: "Students"
)

mph_collection = Collection.find("40acd700-b850-4e7b-a650-0535de84ab6b")

students_col = Collection.new(
  title: 'Students\' Collection',
  tag: ["Student Works"]
)
students_col.apply_depositor_metadata('institutional-students-system')
students_col.members << mph_collection
students_col.save!

students_col.reload.convert_to_institutional(depositor, nil, admin_group)
