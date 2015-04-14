class GalterCollectionPresenter < Sufia::CollectionPresenter
  def self.terms
    [
      :multi_page,
      :resource_type,
      :title,
      :total_items,
      :size,
      :creator,
      :contributor,
      :description,
      :abstract,
      :bibliographic_citation,
      :tag,
      :rights,
      :publisher,
      :date_created,
      :subject,
      :mesh,
      :lcsh,
      :subject_geographic,
      :subject_name,
      :language,
      :identifier,
      :based_near,
      :related_url,
      :digital_origin,
      :page_number
    ]
  end

  def number_of_pages
    total_items
  end

  def [](key)
    key = :total_items if key == :number_of_pages
    super
  end
end
