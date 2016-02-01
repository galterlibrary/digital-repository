module BlacklightConfigurationHelper
  include Blacklight::ConfigurationHelperBehavior

  def sort_fields
    selected = active_sort_fields
    if @collection.blank? || !@collection.try(:multi_page)
      selected = selected.reject{|k,v|
        k.include?('page_number') }
    end
    selected.map { |key, x| [x.label, x.key] }
  end
end
