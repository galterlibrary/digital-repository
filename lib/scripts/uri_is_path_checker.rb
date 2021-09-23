#!/usr/bin/env ruby


def extract_pattern(uri)
  uri.split("staging/").pop.gsub("/content", "")
  #uri.split("dev/").pop.gsub("/content", "")
end

def potential_path(pattern)
  "/var/www/apps/galter_hydra_jetty/shared/fcrepo4-data/fcrepo.binary.directory/#{pattern}"
  #"/Users/asr4267/work/hydra-jetty/fcrepo4-data/fcrepo.binary.directory/#{pattern}"
end

generic_files = GenericFile.all

total = 0
errors = 0
generic_files.each do |gf|
  total += 1
  uri = gf.content.uri.value
  pattern = extract_pattern(uri)
  potential_file = potential_path(pattern)
  if !File.exists?(potential_file)
    errors += 1
    print("#{uri} doesn't correspond to potential path #{potential_file}\n")
  end
end

print("Error rate #{errors}/#{total}\n")
