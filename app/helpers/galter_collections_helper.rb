module GalterCollectionsHelper
  def galter_docs
    @document_list.select {|o|
        o.depositor == 'galter-is'
    }.each_with_index do |col, idx|
      yield col, idx
    end
  end

  def non_galter_docs
    @document_list.reject {|o|
        o.depositor == 'galter-is'
    }.each_with_index do |col, idx|
      yield col, idx
    end
  end
end
