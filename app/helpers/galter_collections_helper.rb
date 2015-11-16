module GalterCollectionsHelper
  def collection_groups
    {
      'galter-is' => 'Galter Health Sciences Library Collections',
      'ipham-system' => 'Institute for Public Health and Medicine'
    }
  end

  def collection_docs_with_depositor(depositor)
    @document_list.select {|doc|
        doc.depositor == depositor
    }.each_with_index do |col, idx|
      yield col, idx
    end
  end

  def users_collection_docs
    @document_list.reject {|o|
        collection_groups.include?(o.depositor)
    }.each_with_index do |col, idx|
      yield col, idx
    end
  end
end
