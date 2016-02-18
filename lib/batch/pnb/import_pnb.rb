pnb_path = ENV['PNB_PATH']
depositor = 'institutional-pnb'
admin_group = 'PNB-Admin'

def parse_xml(path)
  @xml = Nokogiri::XML(open(path))
end

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
  rescue ActiveFedora::ObjectNotFoundError
  end
end

def find_or_create_gf(id, metadata, parent=nil)
  gf = find_or_initialize_object_type(GenericFile, id, metadata)
  persist_or_update(gf, metadata, parent)
end

def find_or_create_collection(id, metadata, parent=nil)
  col = find_or_initialize_object_type(Collection, id, metadata)
  persist_or_update(col, metadata, parent)
end

def find_or_initialize_object_type(object_type, id, metadata)
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

def reset_collection_metadata
  @metadata = nil
end

def collection_metadata
  @metadata ||= {
    title: nil,
    description: 'Pediatric Neurology Briefs is an Open Access (OA) continuing education service designed to expedite and facilitate the review of current scientific research and advances in child neurology and related subjects. The editors provide detailed monthly summaries of published articles, followed by commentaries based on their experience and corroborated by appropriate supplementary citations. Pediatric Neurology Briefs provides pediatric neurologists, neurologists, neurosurgeons, pediatricians, psychiatrists, psychologists, educators and other health professionals with a detailed reference guide to the diagnosis, etiology, pathology, treatment and prognosis of nervous diseases of infants, children and adolescents. Content is intended to be accessible to readers in any medical discipline.',
    publisher: ['Galter Health Sciences Library'],
    original_publisher: [],
    date_created: [],
    language: ['English'],
    identifier: [],
    based_near: [],
    tag: ['Pediatrics', 'Neurology'],
    rights: ['http://creativecommons.org/licenses/by/4.0/'],
    institutional_collection: true,
  }
end

def parse_collection_metadata
  reset_collection_metadata
  collection_metadata[:title] = xml.xpath(
    '//journal-meta/journal-title-group/journal-title').text.strip

  collection_metadata[:identifier] = xml.xpath(
    '//journal-meta/journal-id[not(contains(@journal-id-type,"issn"))]'
  ).map {|id_node|
    "#{id_node['journal-id-type']}: #{id_node.text.strip}"
  }.flatten.compact  + xml.xpath('//journal-meta/issn').map {|issn_node|
    "#{issn_node['pub-type'].first}-ISSN: #{issn_node.text.strip}"
  }.flatten.compact

  collection_metadata[:original_publisher] = [xml.xpath(
    '//journal-meta/publisher/publisher-name').text.strip]

  collection_metadata[:based_near] = [xml.xpath(
    '//journal-meta/publisher/publisher-loc').text.strip]

  collection_metadata[:date_created] = [xml.xpath(
    '//article-meta/pub-date/year').first.text.strip]
end

def reset_article_metadata
  @ametadata = nil
end

def article_metadata
  @ametadata ||= {
    title: [],
    description: [],
    publisher: ['Galter Health Sciences Library'],
    original_publisher: [],
    date_created: [],
    language: ['English'],
    identifier: [],
    based_near: [],
    tag: ['Pediatrics', 'Neurology'],
    rights: ['http://creativecommons.org/licenses/by/4.0/'],
    doi: [],
    resource_type: ['Article'],
    mesh: [],
    subject: [],
    creator: [],
    abstract: [],
  }
end

def find_subjects
  xml.xpath(
    '//article-meta/article-categories/subj-group/subject'
  ).inject({ mesh: [], generic: [] }) do |sh, subject_xml|
    subject = subject_xml.text.strip
    if mesh = Qa::SubjectMeshTerm.find_by(
                term_lower: subject.downcase).try(:term)
      sh[:mesh] << mesh
    else
      sh[:generic] << subject
    end
    sh
  end
end

def find_authors
  xml.xpath(
    '//article-meta/contrib-group/contrib[@contrib-type="author"]/name'
  ).map do |name|
    last_name = name.xpath('./surname').text.strip
    first_name = name.xpath('./given-names').text.strip
    "#{last_name}, #{first_name}"
  end
end

def check_license
  unless xml.xpath('//article-meta/permissions/license').text.include?(
                      'Creative Commons Attribution 4.0 International')
    raise "Unrecognized license for #{article_metadata[:identifier]}"
  end
end

def parse_article_metadata
  reset_article_metadata
  article_metadata[:title] = [xml.xpath(
    '//article-meta/title-group/article-title').text.strip]

  subjects = find_subjects
  article_metadata[:mesh] = subjects[:mesh]
  article_metadata[:subject] = subjects[:generic]

  article_metadata[:identifier] = [xml.xpath(
    '//article-meta/article-id[@pub-id-type="publisher-id"]').text.strip]

  article_metadata[:doi] = [xml.xpath(
    '//article-meta/article-id[@pub-id-type="doi"]').text.strip]

  article_metadata[:original_publisher] = [xml.xpath(
    '//journal-meta/publisher/publisher-name').text.strip]

  article_metadata[:based_near] = [xml.xpath(
    '//journal-meta/publisher/publisher-loc').text.strip]

  article_metadata[:date_created] = [xml.xpath(
    '//article-meta/pub-date/year').first.text.strip]

  article_metadata[:creator] = find_authors

  article_metadata[:abstract] = [xml.xpath(
    '//article-meta/abstract[@abstract-type="web-summary"]').text.strip]

  article_metadata[:tag] = xml.xpath(
    '//article-meta/kwd-group/kwd'
  ).map {|tag| tag.text.strip }

  check_license
end

def root_collection
  parse_collection_metadata
  find_or_create_collection('pedneurbriefs', collection_metadata)
end

def article_pnb_id
  xml.xpath(
    '//article-meta/article-id[@pub-id-type="publisher-id"]'
  ).text.strip.split('-')
end

def volume_collection
  root_col = root_collection
  parse_collection_metadata

  volume = xml.xpath('//article-meta/volume').text.strip
  id = "pnb-#{volume}"

  volume.prepend('0') if volume.length == 1
  collection_metadata[:title] = "Pediatric Neurology Briefs: Volume #{volume}"

  find_or_create_collection(id, collection_metadata, root_col)
end

def find_article_issue
  vol_col = volume_collection
  parse_collection_metadata

  issue = xml.xpath('//article-meta/issue').text.strip
  id = "#{vol_col.id}-#{issue}"

  issue.prepend('0') if issue.length == 1
  collection_metadata[:title] = "#{vol_col.title}, Issue #{issue}"

  year = xml.xpath('//article-meta/pub-date/year').first.text.strip.to_i
  month = xml.xpath('//article-meta/pub-date/month').first.text.strip.to_i
  day = xml.xpath('//article-meta/pub-date/day').first.text.strip.to_i
  collection_metadata[:date_created] = [Date.new(year, month, day)]

  find_or_create_collection(id, collection_metadata, vol_col)
end

def add_content(gf, path)
  unless gf.content.present?
    gf.label = File.basename(path)
    gf.date_uploaded = DateTime.now
    gf.add_file(
      File.open(path.gsub('.xml', '.pdf')),
      original_name: gf.label,
      path: 'content',
      mime_type: 'application/pdf'
    )
    gf.characterize
    gf.create_derivatives
    gf.save!
  end
end

def add_article(path)
  collection_parent = find_article_issue
  parse_article_metadata
  pnb, volume, article_number = article_pnb_id
  id = "#{collection_parent.id}-#{article_number}"
  gf = find_or_create_gf(id, article_metadata, collection_parent)
  add_content(gf, path)
end

User.find_or_create_by(
  username: 'institutional-tmp',
  email: 'institutional-tmp@northwestern.edu'
)

Find.find(pnb_path) do |path|
  if path.include?('.xml')
    parse_xml(path)
    add_article(path)
  end
end

root_collection.reload.convert_to_institutional(depositor, nil, admin_group)
