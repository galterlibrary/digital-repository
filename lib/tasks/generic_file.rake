namespace :generic_file do
  desc "Move descriptive page numbers to actual page number in multi-page collections"
  task migrate_page_numbers: :environment do
    Collection.where('multi_page_bsi' => 'true').each do |col|
      @current = 0
      col.pagable_members.each_with_index do |gf, idx|
        puts "Page Number blank for #{gf.id}: #{gf.title}" if gf.page_number.blank?
        @current += 1
        gf.page_number_actual = @current
        gf.save!
      end
    end
  end
end
