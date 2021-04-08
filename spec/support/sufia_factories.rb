def make_generic_file(user, args={})
  gf = build_generic_file(user, args)
  gf.save!
  gf
end

def make_generic_file_with_content(user, args={})
  gf = build_generic_file(user, args)
  gf.add_file(File.open(File.expand_path("../../fixtures", __FILE__) + '/text_file.txt'), path: 'content', original_name: 'world.png')
  gf.save!
  gf
end

def build_generic_file(user, args={})
  args[:title] = ['testing'] unless args[:title].present?
  gf = GenericFile.new(args)
  gf.apply_depositor_metadata(user.user_key)
  if args[:visibility].present?
    gf.visibility = args[:visibility]
  end
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
