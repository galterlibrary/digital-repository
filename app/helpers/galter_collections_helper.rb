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
    }.map.with_index do |col, idx|
      [col, idx]
    end
  end

  def collection_size
    return number_to_human_size(0) if @collection.members.count == 0
    all_members = @collection.members_from_solr
    selected_members = all_members.select {|member|
      can?(:read, member['id'])
    }
    size = selected_members.reduce(0) {|sum, f|
      sum + f[Solrizer.solr_name('file_size', :stored_long)].to_i
    }
    number_to_human_size(size)
  end

  def users_collection_docs
    @document_list.reject {|o|
      o.depositor =~ /institutional-/
    }.each_with_index do |col, idx|
      yield col, idx
    end
  end
end
