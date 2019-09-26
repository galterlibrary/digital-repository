# https://github.com/galterlibrary/digital-repository/issues/691
# Create 10 'template' institutional collections, adding another 3 template
# collections to each. For more immediate use when needed.

# NUCATS Grants Repository
parent_nucats_grants = Collection.find("f2bf6e1d-0e32-4ce2-a52e-bb0522d5708d")

10.times do |i|
  date = Time.now.strftime("%m-%d-%y")

  template = Collection.new(
    title: "template-#{i} (#{date})",
    tag: ["grant proposals", "research support", "peer-reviewed grants"]
  )
  template.apply_depositor_metadata(parent_nucats_grants.depositor)
  template.save!

  3.times do |child_i|
    child = Collection.new(
      title: "child-#{child_i}-of-template-#{i} (#{date})",
      tag: ["grant proposals", "research support", "peer-reviewed grants"]
    )
    child.apply_depositor_metadata(parent_nucats_grants.depositor)
    child.save!

    template.members << child

    # because we have a before create action that sets visibility to "open"
    child.update_attributes(visibility: "restricted")
  end

  parent_nucats_grants.members << template
  parent_nucats_grants.save!

  # because we have a before create action that sets visibility to "open"
  template.visibility = "restricted"
  template.save!

  template.convert_to_institutional(
    "institutional-nucats-grants-repository",
    parent_nucats_grants.id
  )
end
