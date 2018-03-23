def make_generic_file(user, args = {})
  args[:title] = ['testing'] unless args[:title].present?
  gf = GenericFile.new(args)
  gf.apply_depositor_metadata(user.user_key)
  if args[:visibility].present?
    gf.visibility = args[:visibility]
  end
  gf.save!
  gf
end

def make_page(user, args = {})
  args[:title] = ['testing'] unless args[:title].present?
  args[:doi] = ['doing'] unless args[:doi].present?
  gf = Page.new(args)
  gf.apply_depositor_metadata(user.user_key)
  if args[:visibility].present?
    gf.visibility = args[:visibility]
  end
  gf.save!
  gf
end

def make_collection(user, args = {})
  args[:title] = 'testing' unless args[:title].present?
  args[:tag] = ['tag'] unless args[:tag].present?
  col = Collection.new(args)
  col.apply_depositor_metadata(user.user_key)
  col.save!
  if args[:visibility].present?
    col.visibility = args[:visibility]
    col.save
  end
  col
end
