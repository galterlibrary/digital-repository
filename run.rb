#!/bin/env ruby
require './ead_fc'

# unbuffer output.
STDOUT.sync = true

if ARGV.size == 0
  print "Usage: #{$0} collction_config_file.rb\n"
  exit
end

# The command line arg is the config file name

myfile = ARGV[0]

require myfile

if File.exists?(Ead_file)
  fxm = Ead_fc::Fx_maker.new(Ead_file, Fx_debug)
else
  print "Can't find file #{Ead_file}\n"
  exit
end
