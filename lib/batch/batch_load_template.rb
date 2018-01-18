depositor = 'institutional-galter'
admin_group = 'Galter-Admin'
log_file = File.open("log/FIXME_errors.log", 'a')
log_file.puts("Starting: #{DateTime.now.to_s}")

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

def find_or_create_gf(id, metadata, parent=nil)
  gf = find_or_initialize_object_type(id, GenericFile, metadata)
  persist_or_update(gf, metadata, parent)
end

def find_or_create_collection(id, metadata, parent=nil)
  col = find_or_initialize_object_type(id, Collection, metadata)
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
  obj.visibility = 'restricted'
  obj.date_modified = DateTime.now
  obj.save!
  obj
end

def collection_metadata
  {
    title: 'FIXME',
    description: '',
    publisher: ['Galter Health Sciences Library'],
    original_publisher: [],
    date_created: [],
    language: [],
    tag: [],
    rights: [],
    creator: []
  }
end

def reset_gf_metadata
  @ametadata = nil
end

def gf_metadata
  @ametadata ||= {
    title: [],
    description: []
    publisher: ['Galter Health Sciences Library'],
    date_created: [],
    language: [],
    tag: [],
    rights: [],
    creator: []
  }
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
  gf = find_or_create_gf("FIXME#{idx}", gf_metadata, @root_collection)
  add_content(gf, uri)
end

User.find_or_create_by(
  username: 'institutional-tmp',
  email: 'institutional-tmp@northwestern.edu'
)

@root_collection = find_or_create_collection('FIXME', collection_metadata)

@html = Nokogiri::HTML(
  open('FIXME')
).at_css('FIXME').xpath('.//a').each_with_index do |a, idx|
  add_document(a['href'], a.text.strip, idx)
end

if ARGV[1] == 'true' || ARGV[1].blank?
  @root_collection.reload.convert_to_institutional(depositor, nil, admin_group)
end

log_file.puts("Ending: #{DateTime.now.to_s}")
log_file.close
