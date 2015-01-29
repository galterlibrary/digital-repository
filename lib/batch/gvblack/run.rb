#!/bin/env ruby
Dir.chdir 'lib/batch/gvblack/'
require './ead_fc'

# unbuffer output.
STDOUT.sync = true

myfile = './config.dist.rb'

require myfile

if File.exists?(Ead_file)
  fxm = Ead_fc::Fx_maker.new(Ead_file, Fx_debug)
else
  print "Can't find file #{Ead_file}\n"
  exit
end
