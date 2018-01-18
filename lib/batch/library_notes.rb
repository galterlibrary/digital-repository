# Run `lib/batch/library_notes_extact_dates.sh' and make sure that
# the dates have been extracted properly.
# ARGV[0] - path to the pdfs and date files
# ARGV[1] - make into institutional collection? (true/false)
# ARGV[2] - id of the parent collection (optional)
#
depositor = 'institutional-galter'
admin_group = 'Galter-Admin'
log_file = File.open("log/library_notes_errors.log", 'a')
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
  obj.visibility = 'open'
  obj.date_modified = DateTime.now
  obj.save!
  obj
end

def collection_metadata
  shared_metadata.merge({
    title: 'Library Notes',
    description: '',
    date_created: ['1995-2008'],
    private_note: ["This is only a segment of the longer run of this newsletter. The remaining years are not yet digitized. Library notes (Galter Health Sciences Library) Chicago : Galter Health Sciences Library 1990-2004. Library notes (Archibald Church Library) Chicago : Northwestern University Medical Library 1986-1990"]
  })
end

def shared_metadata
  {
    publisher: ['Galter Health Sciences Library'],
    original_publisher: ['Galter Health Sciences Library'],
    language: ["English"],
    tag: ["Newsletter", "Galter Health Sciences Library"],
    rights: ['All rights reserved'],
    based_near: ["Chicago, Illinois, United States"],
    mesh: ["Libraries, Medical", "Chicago"],
    creator: ['Galter Health Sciences Library']
  }
end

def reset_gf_metadata
  @ametadata = nil
end

def gf_metadata
  @ametadata ||= shared_metadata.merge({
    title: [],
    description: [],
    date_created: [],
  })
end

def add_content(gf, filename)
  unless gf.content.present?
    path = "#{ARGV[0]}/#{filename}"
    gf.label = File.basename(path)
    gf.date_uploaded = DateTime.now
    gf.add_file(
      File.open(path),
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

def add_document(nr)
  reset_gf_metadata
  gf_metadata[:title] = ["Library Notes ##{nr.to_s.rjust(2, '0')}"]
  gf_metadata[:date_created] = [get_date(nr)]
  gf = find_or_create_gf("library-notes-#{nr}", gf_metadata, @root_collection)
  add_content(gf, "#{nr}.pdf")
end

def add_document_from_file(fname)
  reset_gf_metadata
  if nr = fname.match(/libnotes(\d+).pdf/).try(:[], 1)
    title = "Library Notes ##{nr.to_s.rjust(2, '0')}"
    id = "library-notes-#{nr}"
  elsif fname =~ /specialissue.pdf/
    nr = 1
    title = "Library Notes Special Issue ##{nr.to_s.rjust(2, '0')}"
    id = "library-notes-special-issue-#{nr}"
  else
    raise "Unknown file #{fname}"
  end
  gf_metadata[:title] = [title]
  gf_metadata[:date_created] = [File.read("#{ARGV[0]}/#{fname}.date").strip]
  gf = find_or_create_gf(id, gf_metadata, @root_collection)
  add_content(gf, fname)
end

def process_date(node, el)
  date = node.at_xpath(".//#{el}").try(:text)
  if date
    date.split("\n").first
  end
end

def get_date(nr)
  html = Nokogiri::HTML(
    open("http://projects.galter.northwestern.edu/Digital-Projects/Library_Notes/#{nr}")
  )

  left = html.at_css('#left')

  date = left.at_xpath('.//h2').try(:text)
  
  if date.blank?
    ['h3', 'h4', 'strong'].each do |el|
      date = process_date(left, el)
      break if date.present?
    end
  end

  date.try(:strip)
end

User.find_or_create_by(
  username: 'institutional-tmp',
  email: 'institutional-tmp@northwestern.edu'
)

parent = Collection.find(ARGV[2]) if ARGV[2].present?

@root_collection = find_or_create_collection(
  'library-notes', collection_metadata, parent
)

(32..48).each do |nr|
  add_document(nr)
end

Dir.entries(ARGV[0]).select {|o| o =~ /libnotes.*.pdf$/ || o =~ /special.*.pdf$/ }.each do |f|
  add_document_from_file(f)
end

if ARGV[1] == 'true'
  @root_collection.reload.convert_to_institutional(
    depositor, ARGV[2], admin_group
  )
end

log_file.puts("Ending: #{DateTime.now.to_s}")
log_file.close
