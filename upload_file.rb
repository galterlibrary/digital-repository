current_user = User.find(1)
exit 1 unless fname = ARGV[0]
@generic_file = GenericFile.new
file = ActionDispatch::Http::UploadedFile.new(
  tempfile: File.open("/home/phb010/galter_sufia/gvblack/GVBlackArchive/#{fname}"))
file.original_filename = fname.split('/').last
content_type = 'image/tiff'
content_type = 'application/pdf' if fname =~ /.*pdf/
file.content_type = content_type

@actor ||= Sufia::GenericFile::Actor.new(@generic_file, current_user)
@actor.create_metadata(Sufia::Noid.noidify(Sufia::IdService.mint))

if @actor.create_content(file, file.original_filename, 'content')
  puts "Success: #{fname}"
else
  puts "Error: #{fname}"
end

if fname =~ /.*pdf/
  @generic_file.page_count = [`pdfinfo #{file.tempfile.path} |grep 'Pages:' |sed 's/Pages://'`.strip]
end
#@generic_file.mime_type = content_type
@generic_file.title = [rh['title']]
@generic_file.visibility = 'open'
@generic_file.subject = rh['subject']
@generic_file.save!
