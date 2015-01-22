module SufiaHelper
  include ::BlacklightHelper
  include Sufia::BlacklightOverride
  include Sufia::SufiaHelperBehavior

  def number_of_deposits(user)
    ActiveFedora::Base.where(
      Solrizer.solr_name('depositor', :symbol) => user.user_key
    ).count
  end
end
