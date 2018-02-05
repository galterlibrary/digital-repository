# Run `lib/batch/library_notes_extact_dates.sh' and make sure that
# the dates have been extracted properly.
# ARGV[0] - path to the root of audio recordings
# ARGV[1] - make into institutional collection? (true/false)
# ARGV[2] - id of the root collection (required)
#
@depositor = 'institutional-galter'
@admin_group = 'Galter-Admin'
log_file = File.open("log/fsm-interviews_errors.log", 'a')
log_file.puts("Starting: #{DateTime.now.to_s}")
raise 'Required arguments missing' if ARGV[0].blank? || ARGV[2].blank?

@bpath = ARGV[0].strip

@col_titles = {
  "oral-histories" => "Oral Histories",
  "orion-stuteville" => "Orion Stuteville",
  "student-life" => "Student Life",
  "bachelors-degree-1" => "Quo Vadis Medicus? '58 presents: Bachelor's Degree",
  "bachelors-degree-2" => "Quo Vadis Medicus? '58 presents: Bachelor's Degree 2",
  "a-little-culture" => "Quo Vadis Medicus? '59 presents: A Little Culture",
  "paul-de-kruif-interviews" => "Paul de Kruif interviews",
  "health-and-welfare" => "Health & Welfare",
  "the-fight-for-life" => "The Fight for Life",
  "unlabeled-1" => "Untitled interview 1",
  "unlabeled-2" => "Untitled interview 2"
}

@root_id = ARGV[2].strip

def xml
  @xml
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
  rescue Ldp::Gone
    ActiveFedora::Base.eradicate(id)
  rescue ActiveFedora::ObjectNotFoundError
  end
end

def find_or_create_gf(parent=nil)
  gf = find_or_initialize_object_type(
    @ametadata.delete(:id), GenericFile, gf_metadata
  )
  persist_or_update(gf, gf_metadata, parent)
end

def find_or_create_collection(parent=nil)
  #delete_and_eradicate(collection_metadata[:id])
  col = find_or_initialize_object_type(
    @cmetadata.delete(:id), Collection, collection_metadata
  )
  persist_or_update(col, collection_metadata, parent)
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
  @cmetadata ||= shared_metadata.merge({
    title: 'FSM Interviews',
    description: 'Collection of interviews.',
    date_created: ['1938-1959'],
    private_note: []
  })
end

def reset_col_metadata
  @cmetadata = nil
  collection_metadata
end

def shared_metadata
  @cmetadata ||= {
    publisher: ['Galter Health Sciences Library'],
    original_publisher: ['Northwestern University, Medical School'],
    language: ["English"],
    tag: ["History"],
    rights: ['All rights reserved'],
    based_near: ["Chicago, Illinois, United States"],
    mesh: [],
    resource_type: ['Audio Visual Document'],
    creator: ['Northwestern University, Medical School']
  }
end

def reset_gf_metadata
  @ametadata = nil
  gf_metadata
end

def gf_metadata
  @ametadata ||= shared_metadata.merge({
    title: [],
    description: [],
    date_created: [],
  })
end

def add_content(gf, path, mime_type)
  unless gf.content.present?
    gf.label = File.basename(path)
    gf.date_uploaded = DateTime.now
    gf.add_file(
      File.open(path),
      original_name: gf.label,
      path: 'content',
      mime_type: mime_type
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

def photo_metadata(ppath, dir_name)
  reset_gf_metadata
  @ametadata[:date_created] = collection_metadata[:date_created]
  basename = ppath.split('.').first.strip
  @ametadata[:title] = [(
    collection_metadata[:title] + " - " +
    basename.gsub("#{dir_name}_", '').underscore.humanize.titleize
  )]
  @ametadata[:id] = basename.gsub('_', '-').downcase
end

def process_photos(dir_name, col)
  @xml.xpath('//MediaAsset/Original/Photograph').children.each do |ppath|
    photo_metadata(ppath.text, dir_name)
    gf = find_or_create_gf(col)
    full_path = "#{@bpath}/#{dir_name}/#{ppath.text.strip}"
    add_content(gf, full_path, 'image/jpeg')
  end
end

def audio_metadata(master, dir_name)
  reset_gf_metadata
  @ametadata[:date_created] = collection_metadata[:date_created]
  side = master.at_xpath('.//FaceDesignation').text.strip
  @ametadata[:title] = [(
    collection_metadata[:title] + " - " + "Side #{side}"
  )]
  basename = master.at_xpath('.//CustomerFilename').text.split('.').first.strip
  @ametadata[:id] = basename.gsub('_', '-').downcase
  @ametadata[:description] = ["MD5: #{master.at_xpath('.//Checksum').text.strip}"]
  @ametadata[:description] += ["Running time: #{master.at_xpath('.//RunningTime').text.strip}"]
  @ametadata[:description] += ["Bits per sample: #{master.at_xpath('.//BitPerSample').text.strip}"]
  @ametadata[:description] += ["Bit rate: #{master.at_xpath('.//BitRate').text.strip}"]
  @ametadata[:description] += ["Sample rate: #{master.at_xpath('.//SampleRate').text.strip}"]
end

def process_audio(dir_name, col)
  @xml.xpath('//MediaAsset/PreservationMaster').each do |master|
    xml_meta = master.at_xpath('.//MediaKeeper')
    audio_metadata(xml_meta, dir_name)
    gf = find_or_create_gf(col)
    full_path = "#{@bpath}/#{dir_name}/#{master.at_xpath('.//CustomerFilename').text.strip}"
    add_content(gf, full_path, 'audio/x-wav')
    gf.check_doi_presence
  end
end

def col_metadata_from_xml
  reset_col_metadata
  orig = @xml.at_xpath('//MediaAsset/Original')
  @cmetadata[:date_created] = [orig.at_xpath('//RecordDate').text.strip]
  @cmetadata[:id] = orig.at_xpath('//Title').text.strip.gsub('_', '-').downcase
  @cmetadata[:private_note] = [orig.at_xpath('//TransferComments').text.strip]
  @cmetadata[:title] = @col_titles[collection_metadata[:id]]
  raise "No title for #{collection_metadata[:id]}" if collection_metadata[:title].blank?
end

def add_audio_collection(dir_name)
  dir_path = "#{@bpath}/#{dir_name}"
  @xml = Nokogiri::XML(File.open(
    "#{dir_path}/#{dir_name}.xml"
  ))
  col_metadata_from_xml
  col = find_or_create_collection
  process_photos(dir_name, col)
  process_audio(dir_name, col)
end

User.find_or_create_by(
  username: 'institutional-tmp',
  email: 'institutional-tmp@northwestern.edu'
)

@special_collection = Collection.find(@root_id)

Dir.entries(@bpath).select {|o| o !~ /\./ }.each do |f|
  next if f =~ /_copy2/
  puts f
  add_audio_collection(f)
end

@hierarchy = {
  @root_id => {
    'oral-histories' => {},
    'student-life' => {
      'bachelors-degree-1' => {},
      'bachelors-degree-2' => {},
      'a-little-culture' => {}
    },
    'paul-de-kruif-interviews' => {
      'health-and-welfare' => {},
      'the-fight-for-life' => {},
      'unlabeled-1' => {},
      'unlabeled-2' => {}
    }
  }
}

def hierarchy_entry(col, current_hierarchy)
  ch = current_hierarchy[col.id]
  ch.keys.each do |cid|
    # Awkwared, because I want to update Oral Histories
    # but not update the other audio collections
    next if ch[cid].blank? && cid != 'oral-histories'

    reset_col_metadata
    @cmetadata[:id] = cid
    @cmetadata[:title] = @col_titles[cid]
    hierarchy_entry(
      find_or_create_collection, ch
    )
  end

  puts "Adding members for: #{col.id}"
  col.member_ids += ch.keys
  col.save!
  col.update_index

  if ARGV[1] == 'true' && col.id != @root_id
    col.reload.convert_to_institutional(
      @depositor, @root_id, @admin_group
    )
  end
end

puts 'Creating hierarchy'
hierarchy_entry(@special_collection, @hierarchy)

log_file.puts("Ending: #{DateTime.now.to_s}")
log_file.close
