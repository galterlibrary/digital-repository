module GalterCollectionsHelper
  def collection_groups
    {
      'galter-is' => 'Galter Health Sciences Library Collections',
      'ipham-system' => 'Institute for Public Health and Medicine'
    }
    @document_list.select {|doc| doc.depositor =~ /institutional-.*-root/ }
  end

  def institutional_children(ids)
    @document_list.select {|doc|
      ids.include?(doc.id)
    }.each_with_index do |col, idx|
      yield col, idx
    end
  end

  def users_collection_docs
    @document_list.reject {|o|
      o.depositor =~ /institutional-/
    }.each_with_index do |col, idx|
      yield col, idx
    end
  end
end
