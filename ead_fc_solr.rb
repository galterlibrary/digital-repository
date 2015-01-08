#!/usr/bin/ruby 

# Copyright 2011 University of Virginia
# Created by Tom Laudeman

# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You
# may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.

require 'rubygems'
require 'rest-client'
require 'nokogiri'
require 'erb'
require 'mime/types'
require 'config.rb'
require 'find'
require "active-fedora"
require "solrizer-fedora"
require "active_support"


module Ead_fc
  
  class Fx_file_info
    # Generate some technical metadata about digital objects (aka
    # born-digital files) that are part of the collection. This work
    # really should be done by Rubymatica which processes a
    # collection, gathers technical metadata in (more or less)
    # standard formats, and builts a Bagit bag.

    def initialize()

      # A hash of lists of hashes
      @fi_h = Hash.new
      Find.find(Content_home) { |file|
        if File.file?(file)
          rh = Hash.new()
          cpath = File.dirname(file)
          # Path relative to the base Content_home. We can generate
          # rh['fname'] from the c0x id using the Content_path sprintf
          # format string.

          rh['fname'] = file.match(/#{Content_home}\/(.*)/)[1]

          # Can't use MIME::Types.type_for() because is can't
          # recognize certain files such as disk images.
          # rh['format'] = MIME::Types.type_for(file).first.media_type
          # rh['mime'] = MIME::Types.type_for(file).first.content_type
          

          rh['format'] = `file -b #{file}`.chomp
          rh['mime'] = `file -b --mime-type #{file}`.chomp
          rh['size'] = File.size(file)
          # Use the shell commands because we can't read really large
          # files into RAM
          rh['md5'] = `md5sum #{file}`.match(/^(.*?)\s+/)[1]
          rh['sha1'] = `sha1sum #{file}`.match(/^(.*?)\s+/)[1]
          rh['url'] = "#{Content_url}/#{rh['fname']}"
          
          if ! @fi_h.has_key?(cpath)
            @fi_h[cpath] = []
          end
          @fi_h[cpath].push(rh)
        end
      }
    end

    def get(cpath)
      # Return a list of hashes
      return @fi_h[cpath]
    end
  end # end class Fx_file_info

  class Fx_maker
    
    # memnonic: Fedora xml maker. This class has all the action in
    # initialize() in the sense that calling the new() results not
    # only in a new Fx_maker object, but all the action of converting
    # EAD to FoXML occurs as well. All the other methods are simply
    # here for support.
    
    attr_reader :pid

    def initialize(fname, debug)

      # ruby-1.8.7-head > ActiveFedora.version NameError:
      # uninitialized constant ActiveFedora::VERSION from
      # /home/twl8n/.rvm/gems/ruby-1.8.7-head@baretull/gems/active-fedora-3.0.3/lib/active_fedora.rb:268:in
      # `version' from (irb):4

      # Full path to the fedora yaml, and solr assumes that it will
      # find solr.yml in the same dir.

      # Can't use ActiveFedora.version == "2.2.2" due to the bug above in 3.0.3.

      # Sometime after 2.2.2 passing of the config file as a string
      # was deprecated. Put in a little workaround to keep v 3.x.x
      # from complaining.

      # Unfortunately, the new separate yml files don't work with the
      # old version resulting in an error "`init': undefined method
      # `[]' for nil:NilClass (NoMethodError)" from
      # active_fedora.rb:64. Therefore you must copy the proper
      # *_dist.yml files. See the readme.txt.

      if ActiveFedora.constants.include?("VERSION") &&
          ActiveFedora.const_get("VERSION") < "3.0.0"
        ActiveFedora.init(Fedora_yaml)
      else
        ActiveFedora.init(:fedora_config_path=>Fedora_yaml)
      end

      @use_solr = true

      begin
        @solrizer = Solrizer::Fedora::Solrizer.new()
      rescue
        print "Solrizer failed to connect, but we will continue working without it.\n"
        @use_solr = false
      end

      # read the EAD
      # pull info from collection, make foxml
      # Use a foxml erb template
      # foreach container, pull info, make foxml
      # ingest each foxml into Fedora via rest.
      
      # ef_ prefix is memnonic for ead_fedora, system technical data

      @debug = false
      if debug
        @debug = true
      end

      @fname = fname
      @base_url = Base_url
      print "Base URL: #{@base_url}\n"
      @pid_namespace = Pid_namespace
      @ef_create_date = todays_date()
      @fi_h = Ead_fc::Fx_file_info.new()

      # Someone should explain each of the args for ERB.new.
      @generic_template = ERB.new(File.new(Generic_t_file).read, nil, "%")
      @contentmeta_template = ERB.new(File.new(Contentmeta_t_file).read, nil, "%")

      @xml = Nokogiri::XML(open(@fname))
      
      # Make smarter code that can figure out the default namespace.

      @ns = ""
      if @xml.namespaces.size >= 1
        @ns = "xmlns:"
      end

      # collection/container list of hash. Data for each foxml object is
      # in one of the array elements, and each element is a hash.

      @cn_loh = []

      # A new hash. We'll push this onto @cn_loh.
      
      # First a singular bit of code for the collection, then below is a
      # loop for each container.

      rh = Hash.new()

      rh['pid'] = gen_pid()
      @top_pid = rh['pid'] 
      rh['ef_create_date'] = @ef_create_date
      rh['is_container'] = false

      # Ruby objects are always passed by reference. (Except Fixnum.)
      # collection_parse updates rh. Side effects prevent bugs, right?

      collection_parse(rh)
      rh['files_datastream'] = ""
      @top_project = rh['project']

      # binding() passes the current execution heap space.
      # Why don't we move these lines inside collection_parse()?
      
      @xml_out = @generic_template.result(binding())
      wfx_name = write_foxml(rh['pid'])
      print "Wrote foxml: #{wfx_name} pid: #{rh['pid']} id: #{rh['id']}\n"
      ingest_internal(rh['pid'])

      # Push the collection data onto the big loh so that the
      # collection's children can access their parent's data.

      @cn_loh.push(rh)

      # Process the container elements, parse, create foxml, ingest,
      # write to file.  Modifies @cn_loh. Why are we setting nset
      # outside of container_parse()?

      nset = @xml.xpath("//*/#{@ns}archdesc/#{@ns}dsc")
      container_parse(nset)

    end # initialize


    def container_parse(nset)
      @break_set = false

      # Note: we modify @cn_loh in this method.
      
      if nset.children.to_s.match(/<c\d+/is).nil?
        # No child containers, so we must be a leaf container aka we
        # describe individual items.
        return true
      end

      # If we aren't using the index xx, remove it.

      nset.children.each_with_index { |ele,xx|
        #debug
        if @debug && (xx > 5 || @break_set)
          print "dev testing break after 30 containers\n"
          @break_set = true
          break
        end
        
        rh = Hash.new()

        if ele.name.match(/^c\d+/i)

          # Actions to implment here: Get Fedora PID. Get parent PID
          # from the stack. Save current node info in a hash, push onto
          # the container stack, generate foxml, ingest.

          rh['pid'] = gen_pid()
          rh['ef_create_date'] = @ef_create_date
          rh['is_container'] = true
          rh['type_of_resource'] = 'container="yes"'
          rh['parent_pid'] =  @cn_loh.last['pid']

          # container id (attr), container level (attr),
          # container (element, c01, c02, ...), unittitle, container
          # type (attr), container (value, string, could be "6-7"), may be
          # multiple <container> elements), unitdate, scopecontent

          rh['container_element'] = ele.name
          rh['container_level'] = ele.attribute('level')
          rh['container_id'] = ele.attribute('id')
          rh['type_of_resource'] = rh['container_level']
          rh['type'] = rh['container_level']
          rh['id'] = rh['container_id']
          rh['creator'] = "See collection object #{@top_pid}"
          rh['corp_name'] = "See collection object #{@top_pid}"
          rh['object_type'] = rh['container_element']
          rh['set_type'] = "container"
          rh['project'] = @top_project

          # Note: container_type and container_value need to be a list
          # of hash due to possible multiple values!
          
          # These seem to work too, returning the expected single value
          # or nil when there isn't a unitdate.

          # nset.xpath("./#{@ns}c02/#{@ns}c03/#{@ns}did").children.xpath("./#{@ns}unitdate")[0]

          # nset.xpath("./#{@ns}c02/#{@ns}c03/#{@ns}did")[0].xpath("./#{@ns}unitdate")[0]
          
          # Default values.

          rh['container_unitdate'] = ""
          rh['container_unittitle'] = ""
          rh['container_unitid'] = ""

          # <container type="xx"> element(s) are in a list of hashes because we
          # have some with multiples.

          rh['ct'] = Array.new()

          if ele.xpath("./#{@ns}did")[0].class.to_s.match(/nil/i)
            # print "nil did for #{ele.name} #{rh['id']}\n"
            # print "did: #{ele.xpath('./#{@ns}did').to_s}\n"
          else
            ele.xpath("./#{@ns}did")[0].children.each { |child|
              
              if child.name.match(/container/)
                # There could be several of these, so push onto a list.
                ch = Hash.new
                ch['container_type'] = child.attribute('type')
                ch['container_value'] = child.content
                rh['ct'].push(ch)
              end
              
              # We're only expecting zero or one of these, so just
              # assign them. If there are multiples (bad) they'll
              # overwrite and we'll never know unless there's a
              # separate QA step.

              if child.name.match(/unitdate/)
                rh['container_unitdate'] = child.content
              end

              if child.name.match(/unitid/)
                rh['container_unitid'] = child.content
              end
              
              if child.name.match(/unittitle/)
                rh['container_unittitle'] = child.content.strip.gsub!(/\s+/," ")
              end
            }
          end
          rh['create_date'] = rh['container_unitdate']

          # Build the description and title to be more consistent
          # between collection, containers, etc.

          rh['title'] = ""
          details = "Container: #{rh['container_element']} id:#{rh['container_id']} level:#{rh['container_level']}"
          if ! rh['container_unittitle'].to_s.empty?
            rh['title'] = "#{rh['container_unittitle']} "
            rh['description'] = "Title: #{rh['title']} #{details}"
          else
            rh['title'] = details
            rh['description'] = details
          end


          # If the current node is a c01 node then get the
          # scopecontent. If it is not nil look at the children and pull
          # content out of any p elements. Remember that (at least in
          # the nokogiri universe) there are invisible text elements
          # around all other elements.

          rh['container_scope'] = ""
          if ele.name.match(/c01/)
            scon = ele.xpath("./#{@ns}scopecontent")[0]
            if scon.class.to_s.match(/nil/i)
              # When nil do nothing.
            else
              if scon.name.match(/scopecontent/)
                tween = ""
                scon.children.each { |pp|
                  if pp.name.match(/p/)
                    rh['container_scope'].concat("#{tween}#{pp.content.strip.chomp}")
                    tween = "\n\n"
                  end
                }
              end
            end
          end
          rh['scope'] = rh['container_scope']

          # Collection info, most of which doesn't apply to containers,
          # so these are notes for checking correspondence, and things
          # must get from parent if we need them.

          # rh['titleproper'] = @xml.xpath("//*/#{@ns}titleproper[@type='formal']")[0].content
          # rh['title'] = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}unittitle")[0].content
          # rh['creator'] = @xml.xpath("//*/#{@ns}origination[@label='Creator:']/#{@ns}persname")[0].content
          # rh['corp_name'] = ""
          # rh['extent'] = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}physdesc/#{@ns}extent")[0].content
          # rh['abstract'] = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}abstract")[0].content
          # rh['bio'] = ""
          # rh['acq_info'] = ""
          # rh['cite'] = ""
          # rh['type'] = @xml.xpath("//*/#{@ns}archdesc")[0].attributes['level']
          # rh['agreement_id'] = ""
          # rh['project'] = rh['title']

          # The content() method of Nokogiri returns &amp; and similar
          # entities as ascii equivalents which causes problems when we put
          # the content back into XML. Escape everything.
          
          prep_data(rh)

          rh['contentmeta'] = ""

          # Order critical. Push our data onto @cn_loh, then
          # recurse. After we return from recursing, ingest ourself.
          # A true return value from container_parse() means there
          # are no children so we are an ITEM/FILE node. 

          # We only process file data if this is an ITEM container (no
          # child containers) and we have a unitid. Tobin collection
          # unitid has the directory name that contains the files.

          @cn_loh.push(rh)

          # If container_parse() doesn't find any container children,
          # then it returns true meaning 'I am a leaf' thus leaf_flag
          # becomes true.

          leaf_flag = container_parse(ele)
          # printf "lf: %s id: %s\n", leaf_flag, rh['container_unitid']

          if leaf_flag and ! rh['container_unitid'].empty?
            # create a list rh['cm'] that is a list of hash.
            printf("cuid: %s\n", rh['container_unitid'] )
            rh['cm'] = @fi_h.get(sprintf(Content_path, rh['container_unitid']))
            rh['contentmeta'] = @contentmeta_template.result(binding()) 
          end

          @xml_out = @generic_template.result(binding())
          wfx_name = write_foxml(rh['pid'])
          print "Wrote foxml: #{wfx_name} pid: #{rh['pid']} id: #{rh['id']}\n"
          ingest_internal(rh['pid'])


          # Actions to implment here: Pop stack. When we eventually
          # implement "isParentOf" then this is where we will modify the
          # Fedora object created above to know about all the children
          # created during the recursion.

          @cn_loh.pop()

          # debug
          # exit

        end
      }

      # We finished processing which means that we recursed which
      # means we have children which means we are not a
      # leaf. In other words, leaf_flag is false so return false.
      return false
    end # container_parse


    def collection_parse(rh)
      
      # Not used currently, but could be later.
      ead_schema_ns = 'urn:isbn:1-931666-22-9'
      
      # Agnostic variables. This is OOP so it is ok to use instance vars
      # because they won't cause any of the bugs that arise from using
      # globals in imperative code. Obi wan says: These aren't the
      # globals you're looking for.
      
      tmp = @xml.xpath("//*/#{@ns}titleproper[@type='formal']")[0]
      if ! tmp.nil?
        rh['titleproper'] = tmp.content
      else
        printf "tp: %s\n", @xml.xpath("//*/#{@ns}titleproper")
        rh['titleproper'] = @xml.xpath("//*/#{@ns}titleproper")[0].content
      end
      
      rh['title'] = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}unittitle")[0].content

      rh['creator'] = @xml.xpath("//*/#{@ns}origination[contains(translate(@label,'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'creator')]/#{@ns}persname")[0].content
      
      rh['id'] = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}unitid")[0].content

      rh['description'] = "Title: #{rh['title']} Collection: #{rh['id']}"
      
      # Ignore <head>. Get all <p> and separate by \n -->
      
      # Tween always at the beginning. Start with "" and change to the
      # tween string after the first iteration. No knowing what this
      # text will be used for, separate paragraphs with a double
      # newline. 
      
      tween = ""
      rh['scope'] = ""
      @xml.xpath("//*/#{@ns}archdesc/#{@ns}scopecontent/#{@ns}p").each { |ele|
        rh['scope'] += "#{tween}#{ele.content}"
        tween = "\n\n"
      }
      
      # It is hard to know how other institutions will handle this. In
      # the short term using ", " as the tween looks pretty reasonable.

      tween = ""
      rh['corp_name'] = ""
      @xml.xpath("//*/#{@ns}publicationstmt/#{@ns}publisher").each { |ele|
        rh['corp_name'] += "#{tween}#{ele.content}"
        tween = ", "
      }
      
      tmp = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}unitdate")[0]
      if ! tmp.nil?
        rh['create_date'] = tmp.content
      else
        rh['create_date'] = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}unittitle/#{@ns}unitdate")[0].content
      end

      rh['extent'] = ""
      tmp = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}physdesc/#{@ns}extent")[0]
      if ! tmp.nil?
        rh['extent'] = tmp.content
      end

      rh['abstract'] = "" 
      tmp = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}abstract")[0]
      if ! tmp.nil?
        rh['abstract'] = tmp.content
      end
      
      # Not including the <head>. Could be multiple <p> so separate with
      # "\n\n". See comments above about tween.

      tween = ""
      rh['bio'] = ""
      @xml.xpath("//*/#{@ns}archdesc/#{@ns}bioghist/#{@ns}p").each { |ele|
        rh['bio'] += "#{tween}#{ele.content}"
        tween = "\n\n"
      }

      tween = ""
      rh['acq_info'] = ""
      @xml.xpath("//*/#{@ns}archdesc/#{@ns}descgrp/#{@ns}descgrp/#{@ns}acqinfo/#{@ns}p").each { |ele|
        rh['acq_info'] += "#{tween}#{ele.content}"
        tween = "\n\n"
      }
      
      tween = ""
      rh['cite'] = ""
      @xml.xpath("//*/#{@ns}archdesc/#{@ns}descgrp/#{@ns}prefercite/#{@ns}p").each { |ele|
        rh['cite'] += "#{tween}#{ele.content.strip}"
        tween = "\n\n"
      }

      # Used in <mods:identifier type="local">

      # How we know if this is a "collection": <archdesc level="collection"

      # <c01 id="ref11" level="series"> has a
      # <did><unittitle>Inventory</unittitle></did> that could be used
      # to additionally specify the type. Or not.

      # Some containers have a container element that tells us the type,
      # and the box id number. <did><container type="Box">1</container>
      
      rh['type'] = @xml.xpath("//*/#{@ns}archdesc")[0].attributes['level']
      
      # Used in foxml identitymetadata <objectId> and <objectType>

      if (rh['type'] == "collection")
        rh['object_type'] = "set"
        rh['set_type'] = rh['type']
      end
      
      rh['agreement_id'] = ""
      rh['project'] = rh['title']
      
      # The content() method of Nokogiri returns &amp; and similar
      # entities as ascii equivalents which causes problems when we put
      # the content back into XML. Escape everything.

      prep_data(rh)

    end # collection_parse
    
    
    def write_foxml(pid)

      # Use the debug mode both for debugging and for creating files
      # that are part of the documentation. We need copies of the
      # foxml checked in to the version control repo so that new users
      # can see what the expected output is. To generate docs, run in
      # debug mode, then copy the demo_* files to the main dir and add
      # to the repo (github). Ideally, we'd would have collection,
      # series, box, paper archive file, and digital file foxml
      # examples, but that may not be the case because the debug cut
      # off code is very simplistic.

      if @debug
        fn = "demo_" + pid + ".xml"
      else
        fn = pid + ".xml"
      end
      fn.gsub!(/:/,"_")
      writer = lambda {
        File.open(fn, "wb") { |my_xml|
          my_xml.write(@xml_out)
        }
      }
      
      if File.directory?("foxml")
        Dir.chdir("foxml") {
          writer.call 
        }
      else
        writer.call
      end
      return fn;
    end
    

    def ingest_internal(pid)

      # pid is passed in as a convenience for solr. The ingested xml
      # already has a pid, so we don't worry about that.

      # Ingest existing @xml_out. 

      wuri = "#{@base_url}/objects/new?format=info:fedora/fedora-system:FOXML-1.1"
      payload = RestClient::Payload.generate(@xml_out)

      # Do not call to_s() on payload because payload is a stream object
      # and to_s() doesn't reset the stream byte counter which
      # essentially means the stream becomes empty.

      if true
        # deb = payload.inspect()
        # print "working uri: #{wuri}\nvar: #{deb[0,10]}\n...\n#{deb[-80,80]}\n"
        ingest_result_xml = RestClient.post(wuri,
                                            payload,
                                            :content_type => "text/xml")
        begin
          if @use_solr
            @solrizer.solrize(pid) 
          end
        rescue
          puts $!
          print "Solrizer failed. We will continue without it.\n"
          @use_solr = false
        end
        return ingest_result_xml
      else
        var = payload
        # print "working uri: #{wuri}\nvar: #{payload.to_s[0,10]}\n again: #{var}more stuff\n"
        return ""
      end
    end

    def xml_out
      return @xml_out
    end

    def todays_date
      # Example: 2011-07-18T12:34:56.789Z

      # Use GMT time, but hard code the Z since Ruby %Z says "GMT" and
      # Fedora may be expecting a Z (military time zone for UTC).

      # Ruby 1.8.7 strftime() doesn't grok %L, so hard code that as '.000'.

      return Time.now.utc.strftime("%Y-%m-%dT%T.000Z")
    end
    
    def gen_pid
      
      # If we use a "format" param in the URL, then the returned object
      # is of the expected type. If not, it is probably necessary to
      # include a :content_type hash key-value as the third arg to
      # post().

      working_url = "#{@base_url}/objects/nextPID?namespace=#{@pid_namespace}&format=xml"
      some_xml = RestClient.post(working_url, '')
      numeric_pid = some_xml.match(/<pid>#{@pid_namespace}:(\d+)<\/pid>/)[1]

      # Fedora requires pids to match a regex, apparently text:number

      return "#{@pid_namespace}:#{numeric_pid}"
    end

    def ingest(fname)
      
      # Must include the third arg ':content_type => "text/xml"' or we
      # get a 415 Unsupported media type response from the server.

      working_url = "#{@base_url}/objects/new?format=info:fedora/fedora-system:FOXML-1.1"
      some_xml = RestClient.post(working_url,
                                 RestClient::Payload.generate(IO.read(fname)),
                                 :content_type => "text/xml")
      print some_xml
    end

    def prep_data(rh)

      # Ruby objects are always passed by reference. (Except Fixnum.)
      # this def updates rh in place. Side effects prevent bugs,
      # right?

      rh.keys.each { |key|
        if rh[key].class.to_s == 'String'
          # Escape & to &amp; etc.
          rh[key] = CGI.escapeHTML(rh[key])

          # Clean extra whitespace. the content() method (or
          # something we're using) keeps whitespace that resulted
          # from indenting the XML. Ruby \s+ matches spaces and \n
          # (I'm pretty sure \s+ does not match \n in Perl).

          # I wanted to do this: rh[key].strip!.gsub!(/\s+/, ' ')
          # however, ''.strip! => nil so I broke it into several
          # lines which is more intuitive than strip!.to_s.gsub!().
          
          rh[key] = rh[key].strip
          rh[key].gsub!(/\s+/, ' ')
        end
      }
    end
    
  end

end
