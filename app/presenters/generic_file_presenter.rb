class GenericFilePresenter < Sufia::GenericFilePresenter
  self.terms = [
    :resource_type,
    :title,
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
    :digital_origin
  ]
end
