# Institutional Collection: "G.V. Black Papers"
# https://github.com/galterlibrary/digital-repository/issues/776

admin_group = 'GV-Black-Papers-System-Admin'
depositor = 'institutional-gv-black-papers'

gv_black_papers_sys_user = User.create!(
  username: 'institutional-gv-black-papers-system',
  email: 'institutional-gv-black-papers-system@northwestern.edu',
  display_name: "G.V. Black Papers"
)

role = Role.create!(name: admin_group)

gv_black_papers_collection = Collection.new(
  title: 'G.V. Black Papers',
  description: 'Digital images of the original physical manuscripts, correspondence, photographs, and ephemera which are housed in the Galter Health Sciences Library Special Collections.',
  tag: ["Dentistry", "Dental Flourosis", "World's Columbian Dental Congress (1893 : Chicago, Ill.)"],
  resource_type: ["Collected Correspondence", "Manuscript", "Photographs"],
  rights: ["Public Domain Mark 1.0"],
  creator: ['Black, G. V. (Greene Vardiman), 1836-1915'],
  contributor: ['McKay, Frederick S.'],
  abstract: ["The Collection includes: manuscripts on general subjects; correspondence between G.V. Black and Dr. Frederick S. McKay on mottled teeth; photographs; correspondence and other ephemera pertaining to the 1893 World Dental Congress held in conjunction with the 1893 World's Columbian Exposition in Chicago, Illinois"],
  publisher: ["DigitalHub. Galter Health Sciences Library"],
  date_created: ['1867-1915'],
  language: ['English'],
  mesh: ["Dentistry", "Biochemistry", "Zoology", "Tooth Abnormalities", "Fluorosis, Dental--epidemiology", "Chemistry"],
  subject_geographic: ["Colorado", "Jacksonville (Ill.)"],
  subject_name: ["Black, G. V. (Greene Vardiman), 1836-1915", "World's Columbian Exposition (1893 : Chicago, Ill.)"],
  digital_origin: ["Reformatted Digital"]
)

gv_black_papers_collection.apply_depositor_metadata(
  gv_black_papers_sys_user.username
)

gv_black_papers_collection.save!
gv_black_papers_collection.reload.convert_to_institutional(depositor, nil, admin_group)
