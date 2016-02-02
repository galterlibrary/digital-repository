def copy_attribs(col, file)
  if file.blank?
    puts "Empty file for #{col.title}"
    return
  end

  file.contributor = col.contributor
  file.creator = col.creator
  file.description = [col.description]
  file.publisher = col.publisher
  file.subject = col.subject
  file.language = col.language
  file.rights = col.rights
  file.resource_type = col.resource_type
  file.identifier = col.identifier
  file.based_near = col.based_near
  file.tag = col.tag
  file.related_url = col.related_url
  file.abstract = col.abstract
  file.bibliographic_citation = col.bibliographic_citation
  file.digital_origin = col.digital_origin
  file.mesh = col.mesh
  file.lcsh = col.lcsh
  file.subject_geographic = col.subject_geographic
  file.subject_name = col.subject_name
  file.save!
end

def process_collections(collections)
  collections.each do |col|
    puts "Processing: #{col.title}"
    raise "Bad collection: #{collection.id}" unless col.is_a?(Collection)
    col.members.each do |m|
      raise "Bad: member #{m.id} of #{col.id}" if m.is_a?(Collection)
      copy_attribs(col, m)
    end

    if col.combined_file.present?
      puts "Scheduling DOI job for #{col.combined_file.id}"
      copy_attribs(col, col.combined_file)
      Sufia.queue.push(MintDoiJob.new(col.combined_file.id, 'phb010'))
    else
      puts "Combinde file for #{col.title} not found"
    end
  end
end

#Dev
#ids = ['z603qx42h']

#Prod
ser1 = 'm039k4882'
ser2 = 'zk51vg82g'
ser3_1 = 'vx021f146'
ser3_2 = 'bk128b00b'
ser3_3 = '0v8380612'
ser4 = 'x346d4254'
ids = [ser1, ser2, ser3_1, ser3_2, ser3_3, ser4]

ids.each do |id|
  process_collections(Collection.find(id).members)
end
