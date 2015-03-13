class Collection < Sufia::Collection

  def pagable?
    pagable_members.present?
  end

  def pagable_members
    members.reject {|o| o.page_number.blank? }.sort_by {|o| o.page_number.to_i }
  end

  def bytes
    'FIXME in app/models/collection.rb'
  end
end
