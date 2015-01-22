module DashboardHelper
  include Sufia::DashboardHelperBehavior
  def number_of_files user=current_user
    ::GenericFile.where(Solrizer.solr_name('depositor', :symbol) => user.user_key).count
  end

  def number_of_collections user=current_user
    ::Collection.where(Solrizer.solr_name('depositor', :symbol) => user.user_key).count
  end
end
