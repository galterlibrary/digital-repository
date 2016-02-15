galter = User.find_by(username: 'galter-is')
galter.username = 'institutional-galter-system'
galter.save!

galter_root = User.create(username: 'institutional-galter-system-root',
                          email: 'galter-system-root@northwestern.edu',
                          display_name: "Galter Health Sciences Library")

ipham = User.find_by(username: 'ipham-system')
ipham.username = 'institutional-ipham-system'
ipham.save!

ipham_root = User.find_by(username: 'ipham-top-system')
ipham_root.username = 'institutional-ipham-system-root'
ipham_root.save!


ActiveFedora::Base.where('depositor_ssim' => 'galter-is').each do |doc|
  doc.apply_depositor_metadata('institutional-galter-system')
  doc.save!
end

ActiveFedora::Base.where('depositor_ssim' => 'ipham-system').each do |doc|
  doc.apply_depositor_metadata('institutional-ipham-system')
  doc.save!
end

galter_col = Collection.new(title: 'Galter Health Sciences Library Collections', tag: ['Galter Health Sciences Library'])
galter_col.apply_depositor_metadata('institutional-galter-system-root')
galter_col.save!

ipham_col = Collection.find('ipham')
ipham_col.apply_depositor_metadata('institutional-ipham-system-root')
ipham_col.save!

special = Collection.where('title_tesim' => 'Special Collections').first
special.parent = galter_col
special.save!

gvb = Collection.where('title_tesim' => 'G.V. Black Manuscripts, Correspondence and Photographs in the Galter Health Sciences Library, Northwestern University').first
gvb.parent = galter_col
gvb.save!

galter_col.members = [gvb, special]
galter_col.save!
