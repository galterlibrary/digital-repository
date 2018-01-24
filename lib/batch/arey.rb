# ARGV[0] - path to the combined file (required)
# ARGV[1] - make into institutional collection? (true/false)
# ARGV[2] - id of the parent collection (optional)
#
depositor = 'institutional-galter'
admin_group = 'Galter-Admin'
log_file = File.open("log/arey_errors.log", 'a')
log_file.puts("Starting: #{DateTime.now.to_s}")
raise 'Required arguments missing' if ARGV[0].blank?

def html
  @html
end

def processed
  @processed ||= []
end

def persist_or_update(obj, metadata, parent)
  if !obj.persisted?
    create_object(obj)
  elsif !processed.include?(obj.id)
    puts "Updating: #{obj.title}, #{obj.id}"
    processed << obj.id
    obj.date_modified = DateTime.now
    obj.update_attributes(metadata)
  end

  if parent.present?
    parent.members << obj
    parent.save!
  end

  obj
end

def delete_and_eradicate(id)
  begin
    ActiveFedora::Base.find(id).delete
    ActiveFedora::Base.eradicate(id)
  rescue ActiveFedora::ObjectNotFoundError
  end
end

def find_or_create_gf(id, metadata, parent=nil, doc_type=Page)
  gf = find_or_initialize_object_type(id, doc_type, metadata)
  persist_or_update(gf, metadata, parent)
end

def find_or_create_collection(id, metadata, parent=nil)
  col = find_or_initialize_object_type(id, Collection, metadata)
  col.multi_page = true
  persist_or_update(col, metadata, parent)
end

def find_or_initialize_object_type(id, object_type, metadata)
  obj = object_type.find(id)
rescue ActiveFedora::ObjectNotFoundError
  obj = object_type.new(metadata)
  obj.id = id
  obj
end

def create_object(obj, parent=nil)
  puts "Creating: #{obj.title}, #{obj.id}"
  obj.apply_depositor_metadata('institutional-tmp')
  obj.visibility = 'open'
  obj.date_modified = DateTime.now
  obj.save!
  obj
end

def collection_metadata
  shared_metada.merge({
    title: 'Northwestern University Medical School 1859-1979',
    description: "A history of the Feinberg School of Medicine, written by Leslie B. Arey, PhD, a faculty member in the Department of Anatomy from 1919 to 1987.",
    institutional_collection: true
  })
end

def shared_metada
  {
    publisher: ['Galter Health Sciences Library'],
    original_publisher: ['Northwestern University'],
    date_created: ['1979'],
    language: ['English'],
    tag: ['History'],
    rights: ['All rights reserved'],
    mesh: ["Schools, Medical", "History"],
    subject_name: ["Northwestern University (Evanston, Ill.). Medical School"],
    subject_geographic: ["Chicago (Ill.)"],
    creator: ['Arey, Leslie Brainerd, 1891-']
  }
end

def reset_gf_metadata
  @ametadata = nil
end

def gf_metadata
  @ametadata ||= shared_metada.merge({
    title: [],
    description: ["A history of the Feinberg School of Medicine, written by Leslie B. Arey, PhD, a faculty member in the Department of Anatomy from 1919 to 1987."]
  })
end

def add_content(gf, uri)
  unless gf.content.present?
    gf.label = File.basename(uri)
    gf.date_uploaded = DateTime.now
    gf.add_file(
      open(uri),
      original_name: gf.label,
      path: 'content',
      mime_type: 'application/pdf'
    )
    begin
      gf.characterize
    rescue RuntimeError
      puts 'FITS problem, retrying'
      retry
    end
    gf.create_derivatives
    gf.save!
  end
end

def add_document(uri, title, idx)
  reset_gf_metadata
  gf_metadata[:title] = [title]
  gf_metadata[:page_number] = idx + 1
  gf = find_or_create_gf("areybook#{idx}", gf_metadata, @root_collection)
  add_content(gf, uri)
end

def add_full_doc
  reset_gf_metadata
  gf_metadata[:title] = [collection_metadata[:title]]
  gf = find_or_create_gf("areybook-full", gf_metadata, nil)
  add_content(gf, ARGV[0])
  gf.check_doi_presence
  @root_collection.combined_file_id = gf.id
  @root_collection.save!
end

User.find_or_create_by(
  username: 'institutional-tmp',
  email: 'institutional-tmp@northwestern.edu'
)

parent_col = Collection.find(ARGV[2]) if ARGV[2].present?

@root_collection = find_or_create_collection(
  'areybook', collection_metadata, parent_col
)

@html = Nokogiri::HTML(
  open('https://galter.northwestern.edu/digital-projects/arey')
).at_css('#sectionTitle6967').at_css('.section_content').xpath('.//a').each_with_index do |a, idx|
  add_document(a['href'], a.text.strip, idx)
end

add_full_doc

if ARGV[1] == 'true'
  @root_collection.reload.convert_to_institutional(
    depositor, ARGV[2], admin_group
  )
end

log_file.puts("Ending: #{DateTime.now.to_s}")
log_file.close
