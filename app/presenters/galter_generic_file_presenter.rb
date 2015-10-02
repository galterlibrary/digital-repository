class GalterGenericFilePresenter < Sufia::GenericFilePresenter
  self.terms = [
    :title,
    :resource_type,
    :tag,
    :rights,
    :creator,
    :contributor,
    :description,
    :abstract,
    :bibliographic_citation,
    :related_url,
    :publisher,
    :date_created,
    :identifier,
    :language,
    :mesh,
    :lcsh,
    :subject_geographic,
    :subject_name,
    :based_near,
    :digital_origin,
    :page_number
  ]
end
