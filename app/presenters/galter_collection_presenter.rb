class GalterCollectionPresenter < Sufia::CollectionPresenter
  def terms
    self.class.terms
  end

  def self.terms
    [
      :multi_page,
      :title,
      :tag,
      :resource_type,
      :rights,
      :creator,
      :contributor,
      :description,
      :abstract,
      :bibliographic_citation,
      :related_url,
      :publisher,
      :original_publisher,
      :date_created,
      :identifier,
      :language,
      :mesh,
      :lcsh,
      :subject_geographic,
      :subject_name,
      :based_near,
      :digital_origin,
      :total_items,
      :size,
      :private_note
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
