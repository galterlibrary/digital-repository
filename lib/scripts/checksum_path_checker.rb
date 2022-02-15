#!/usr/bin/env ruby
# Checks the error rate of paths created based on a GenericFile's checksum.
# To run from the base directory of this app:
# `$ b rails r lib/scripts/checksum_path_checker.rb`

def generic_file_content_path(checksum)
  # content paths are generated by taking the first 6 characters of its
  # checksum, and dividing it by 3
  "#{ENV["FEDORA_BINARY_PATH"]}/#{checksum[0..1]}/#{checksum[2..3]}/#{checksum[4..5]}/#{checksum}" unless !checksum
end

total = 0
errors = 0
GenericFile.find_each do |gf|
  total += 1
  potential_file = generic_file_content_path(gf.content.checksum.value)
  if !File.exists?(potential_file)
    errors += 1
    print("#{gf.id} doesn't correspond to potential path #{potential_file}\n")
  end
end

print("Error rate #{errors}/#{total}\n")