def make_generic_file(user, args = {})
  args[:title] = ['testing'] unless args[:title].present?
  col = GenericFile.new(args)
  col.apply_depositor_metadata(user.user_key)
  col.save!
  col
end

def make_collection(user, args = {})
  args[:title] = 'testing' unless args[:title].present?
  col = Collection.new(args)
  col.apply_depositor_metadata(user.user_key)
  col.save!
  col
end
