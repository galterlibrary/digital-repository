#!/usr/bin/ruby 
#require "#{Rails.root}/app/models/datastreams/dublin_core_datastream.rb"


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
require 'find'
require 'escape'
require 'sqlite3'
require 'pry'
require 'rack'

# Get file technical meta data. Save it in a hash of list of hashes.

#  class Fx_file_info
#   def initialize()
#   def discover(tpath)
#   def get(cpath)

# class Fx_maker
#   def initialize(fname, debug)
#   def container_parse(nset, parent_path)
#   def collection_parse(rh)
#   def write_foxml(pid)
#   def xml_out
#   def todays_date
#   def gen_pid
#   def ingest(fname)
#   def prep_data(rh)

# Support class used by the SQL stuff in Fx_file_info. Creates a list
# of hash from a SQL request object.

# class Proc_sql
#   def initialize
#   def loh
#   def chew(rset)

module Ead_fc
  
  class Fx_file_info

    # This class is Tobin specific. The failure to use a unique UUID
    # for each file means that we have to parse contextual information
    # from the EAD, and there is no standard for that contextual
    # information. If we had a unique id such as a UUID for each file,
    # I could just search all files (via a hash or SQL database) and I
    # wouldn't need any contextual information.
    
    # Generate some technical metadata about digital objects (aka
    # born-digital files) that are part of the collection. This work
    # really should be done by Rubymatica which processes a
    # collection, gathers technical metadata in (more or less)
    # standard formats, and builts a Bagit bag.

    def initialize()

      @fi_h = Hash.new

      # File Info hash (fi_h), a hash of lists of hashes. The outer
      # hash key is the path, and the list are files in that
      # directory. Since Tobin is essentially flat, the directory is
      # the unitid, and the internal files are all part of the digital
      # "item".

      # Save the technical meta data in a SQLite db. If the db exists,
      # use it, if not create and populate it.

      @fn = "#{Path_key_name}_tech_data.db"

      if (! File.size?(@fn))
        db = SQLite3::Database.new(@fn)
        db.busy_timeout(1000) # milliseconds?
        db.transaction(:immediate)
        db.execute_batch(IO.read(Schema_sql))
        db.commit
        db.close

        print "Building file technical meta data for: #{Digital_assets_home}\n"

        xx = 0
        Find.find(Digital_assets_home) { |file|
          if File.file?(file)
            puts file
            shell_file = Escape.shell_command([file])
            rh = Hash.new()
            cpath = File.dirname(file)
            # Path relative to the base Digital_assets_home. We can generate
            # rh['fname'] from the c0x id using the Content_path sprintf
            # format string.

            rh['fname'] = file.match(/#{Digital_assets_home}\/(.*)/)[1]

            # Create a string that we can test against the
            # path-matching info we can pull out of the EAD XML.
            rh['test_name'] = String.new(rh['fname'].to_s)

            if Path_key_name == 'hull'
              # Remove leading numbers \d+\.\s+ e.g. "1. "
              rh['test_name'].gsub!(/^\d+\.\s+/, "/")

              # Remove numbers after / e.g "/1. "
              rh['test_name'].gsub!(/\/\d+\.\s+/, "/")

              # Remove file name from the end
              rh['test_name'].gsub!(/(.*\/).*/, '\1')

              # Remove trailing /
              rh['test_name'].gsub!(/\/$/, '')
            elsif Path_key_name == 'gvblack'
            else
              # Remove file name from the end
              rh['test_name'].gsub!(/(.*\/).*/, '\1')

              # Remove trailing /
              rh['test_name'].gsub!(/\/$/, '')
              print "rt: #{rh['test_name']}\n"
            end

            # Can't use MIME::Types.type_for() because is can't
            # recognize certain files such as disk images.
            # rh['format'] = MIME::Types.type_for(file).first.media_type
            # rh['mime'] = MIME::Types.type_for(file).first.content_type

            rh['format'] = `file -b #{shell_file}`.chomp
            rh['mime'] = `file -b --mime-type #{shell_file}`.chomp
            rh['size'] = File.size(file)
            # Use the shell commands because we can't read really large
            # files into RAM
            rh['md5'] = `md5sum #{shell_file}`.match(/^(.*?)\s+/)[1]
            rh['sha1'] = `sha1sum #{shell_file}`.match(/^(.*?)\s+/)[1]
            rh['url'] = "#{Digital_assets_url}/#{rh['fname']}"
            rh['cpath'] = String.new(cpath.to_s)
            
            if ! @fi_h.has_key?(cpath)
              @fi_h[cpath] = []
            end
            @fi_h[cpath].push(rh)
            xx = xx + 1

            # if xx == 10
            #   break
            # end
            if (xx % 20) == 0
              print "Completed #{xx}\n"
            end
          end
        }
        print "Finished traversing: #{xx}\n"
        
        db = SQLite3::Database.new(@fn)
        db.busy_timeout(1000) # milliseconds?
        db.transaction(:immediate)
        stmt = db.prepare("insert into file_info (cpath,fname,test_name,format,mime,size,md5,sha1,url) values (?,?,?,?,?,?,?,?,?)")
        
        # hash of list of hash

        @fi_h.keys.each { |key|
          @fi_h[key].each { |rh|
            stmt.execute(rh['cpath'],
                         rh['fname'],
                         rh['test_name'],
                         rh['format'],
                         rh['mime'],
                         rh['size'],
                         rh['md5'],
                         rh['sha1'],
                         rh['url'])
          }
        }
        stmt.close
        db.commit
        db.close
        print "All complete: #{xx}.\n"

      else
        yy = 0
        db = SQLite3::Database.new(@fn)
        db.busy_timeout(1000) # milliseconds?
        db.transaction(:immediate)
        stmt = db.prepare("select * from file_info")
        ps = Proc_sql.new();
        stmt.execute(){ |rs|
          ps.chew(rs)
        }
        stmt.close
        db.close()

        # Get the list of hash from ps and create a hash keyed by
        # cpath and then push each file with that cpath into the list
        # that is the value of the hash.

        ps.loh.each { |hr|
          yy = yy + 1
          # Use a temp var "cpath" for legibility and to be just like the
          # non-db code above.
          cpath = String.new(hr['cpath'].to_s)

          if ! @fi_h.has_key?(cpath)
            # Can't push to a nonexistent hash key in Ruby. 
            @fi_h[cpath] = []
          end
          @fi_h[cpath].push(hr)
        }
        print "Read #{yy} records from file_info database: #{Schema_sql}\n"
        return
      end
      print "Done building file technical meta data for: #{Digital_assets_home}\n"
    end

    def discover(tpath)

      # Check the test_name against a path generated by parsing some
      # data from the <c> container elements. In the case of Hull,
      # test_name is a path that has certain numbers
      # removed. "1. Stuff" becomes "Stuff".

      file_list = []
      @fi_h.keys.each { |key|
        @fi_h[key].each { |rh|
          # print "tpa: #{rh['test_name']}\n
          if rh['test_name'] == tpath
            file_list.push(rh)
          end
        }
      }
      return file_list
    end

    def get(cpath)
      # Return a list of hashes or return an empty list.
      test_key = "#{Digital_assets_home}/#{cpath}"
      if @fi_h.has_key?(test_key)
        return @fi_h[test_key]
      else
        return []  
      end
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

      # Get a Fedora PID via a REST call. Relies on correct Base_url
      # from *_config.rb.

      rh['pid'] = gen_pid()
      @top_pid = String.new(rh['pid'].to_s)

      rh['ef_create_date'] = String.new(@ef_create_date.to_s)
      rh['is_container'] = false

      # Ruby objects are always passed by reference. (Except Fixnum.)
      # collection_parse updates rh. Side effects prevent bugs, right?
      
      collection_parse(rh)
      rh['files_datastream'] = ""
      @top_project = String.new(rh['project'].to_s)

      # binding() passes the current execution heap space.
      # Why don't we move these lines inside collection_parse()?
      
      @xml_out = @generic_template.result(binding())
      wfx_name = write_foxml(rh)
      if rh['fname']
        puts "Processed #{fname}"
      else
        store_collection(rh)
      end
      #print "Wrote foxml: #{wfx_name} pid: #{rh['pid']} id: #{rh['id']}\n"

      # Push the collection data onto the big loh so that the
      # collection's children can access their parent's data.

      @cn_loh.push(rh)

      # Process the container elements, parse, create foxml, ingest,
      # write to file.  Modifies @cn_loh. Why are we setting nset
      # outside of container_parse()?

      nset = @xml.xpath("//*/#{@ns}archdesc/#{@ns}dsc")
      container_parse(nset, "")

    end # initialize


    def create_file_objects(rh_orig)

      # Important that our local hash is named "rh" so that it works
      # with the templates. Also important that it is a copy of the
      # original since we are modifying it, and we do not want to
      # modify a reference to the original and thereby munge the
      # original. Make the copy here in order to hide our strange
      # behavior from the calling code. 

      rh = Hash.new.replace(rh_orig)

      # Put our parent containers pid into the parent_pid so the
      # isMemberOf will be correct.

      rh['parent_pid'] = rh['pid']

      if rh['cm'].size > 0
        rh['cm'].each { |rsrc|
          rh['pid'] = gen_pid()
          
          # contentmeta_template uses rh[] and rsrc[]. Remember that
          # rh[] is a local copy, but rh['pid'] and rh['parent_pid']
          # are the only differences between the copy and the
          # original.
          
          rh['contentmeta'] = @contentmeta_template.result(binding())
          
          @xml_out = @generic_template.result(binding())
          wfx_name = write_foxml(rh)
          #print "Wrote foxml (digital object): #{wfx_name} pid: #{rh['pid']} id: #{rh['id']}\n"
          if rh['fname']
            puts "Processed #{fname}"
          else
            puts "No file for #{rh['title']}"
          end
        }
      end
    end

    def query_from_url(url)
      params = Rack::Utils.parse_nested_query(URI.parse(URI.encode(url)).query)
      query = ''
      if params['man']
        query = params['man']
      elsif params['ltr']
        query = params['ltr']
      elsif params['doc']
        query = params['doc']
      elsif params['eph']
        query = params['eph']
      end

      if url == '../gvblack/wcdc-eph/open.gif'
        query = 'open'
      elsif url == '../gvblack/wcdc-eph/reception.gif'
        query = 'recep'
      elsif url == '../gvblack/wcdc-eph/lunch.gif'
        query = 'lunch'
      end
      query.strip.downcase
    end

    def find_file(file_id, rh)
      file_id = file_id.strip.downcase
      if file_id == 'cm'
        file_id = 'cruisemicrobe'
      elsif file_id == 'ps'
        file_id = 'policesystem'
      elsif file_id == 'fwsa'
        file_id = 'fewwordssalacid'
      elsif file_id == 'd612-33'
        file_id = '612-33'
      elsif file_id == 'm19120227t'
        file_id = 'm19120227'
      elsif file_id == 'b19141114'
        file_id = '19141114'
      elsif file_id == 'b19150429a'
        file_id = 'b19150429'
      elsif file_id == 'hunt18921009'
        file_id = 'black18921009'
      elsif file_id == 'howe189211'
        file_id = 'howe1892'
      elsif file_id == 'bolton18921201'
        file_id = 'bolton1892120'
      elsif file_id == 'black18930307'
        file_id = 'black18930207'
      end

      if !file_id.nil?
        rh['file_id'] = file_id
        Find.find(Digital_assets_home) do |path|
          if path.downcase =~ /.*#{file_id}_full.pdf/
            return path
          end
        end

        file_id = file_id.gsub(/[a-zA-Z]/, '')

        Find.find(Digital_assets_home) do |path|
          if path.downcase =~ /.*#{file_id}_full.pdf/
            rh['file_id'] = file_id
            return path
          end
        end
      end
      puts "Missing File Path for: #{file_id}"
    end

    def store_collection(rh)
      return if rh['type'].to_s.blank?
      title = unescape_and_clean( rh['title'])
      if rh['type'] == 'subseries'
        title = "#{title} - World's Columbian Dental Congress"
      end
      #c = Collection.find {|c| c.title == "#{title}" }
      docs = Blacklight.solr.select(
        params: { q: 'title_tesim:"' + title + '",has_model_ssim:"Collection"' }
      )['response']['docs']
      binding.pry if docs.count > 1
      c = nil
      c = Collection.find(docs.first['id']) if docs.count == 1
      if !c
        c = Collection.new
        c.title = title
        c.apply_depositor_metadata("galter-is@listserv.it.northwestern.edu")
      end
      c.visibility = 'open'
      c.subject = rh['subject']
      c.mesh = rh['mesh']
      c.lcsh = rh['lcsh']
      c.subject_geographic = rh['geoname']
      c.subject_name = (rh['corpname'] || []) + (rh['persname'] || [])
      c.date_created = [normalize_date(rh['create_date'])]
      c.abstract = [rh['abstract']].compact
      c.identifier = [rh['file_id']].compact
      c.rights = ['http://creativecommons.org/publicdomain/mark/1.0/']
      c.digital_origin = ['Reformatted Digital']
      c.description = rh['note']
      c.rights = ['http://creativecommons.org/publicdomain/mark/1.0/']
      c.save!
      ActiveFedora::SolrService.instance.conn.commit
      rh['collection'] = c
      add_to_collection(rh['parent_pid'], rh['collection'])
    end

    def add_to_collection(parent_pid, member)
      col = @cn_loh.find {|o| o['pid'] == parent_pid }
      if col.present?
        if !col['collection'].member_ids.any? {|m| m == member.id }
          col['collection'].members << member
          col['collection'].save!
          member.parent = col['collection']
          member.save!
        end
      end
    end

    def unescape_and_clean(str, postfix='')
      str = CGI::unescapeHTML(str)
      # Remove junk from the end and strip
      # Remove line-breaks and more then one space
      str.strip.gsub(/[,.;]\z/, '').gsub(/[\n\t]/, '').gsub(/ +/, ' ') + postfix
    end

    def get_all_files_for_item(full_name, fid)
      dir = File.dirname(full_name)
      if fid.blank?
        fid = File.basename(full_name).gsub(/#{File.extname(full_name)}/, '')
      end
      pages = {}
      Find.find(dir) do |path|
        path_clean = path.tr('[]()', '').downcase
        if path_clean =~ /.*#{fid}_[0-9]+[a-z]?\.[tg]if/
          page = path_clean.match(/.*#{fid}_([0-9]+[a-z]?)\.[tg]if/i).captures.first
          pages[page] = path
        elsif path_clean =~ /.*#{fid}_figure.*\.[tg]if/ ||
            path_clean =~ /.*#{fid}_title\.[tg]if/ ||
            path_clean =~ /.*#{fid}_tp\.[tg]if/
          page = path_clean.match(/.*#{fid}_(.*)\.[tg]if/i).captures.first
          pages[page] = path
        end
      end
      pages
    end

    def make_file(rh)
      @current_user ||= User.find(6)
      fname = rh['fname']
      pages = get_all_files_for_item(fname, rh['file_id'])
      pages[nil] = fname
      puts pages
      pages.each do |page, path|
        store_gf(rh, page, path)
      end
    end

    def mime_type(extname)
      case(extname)
      when '.tif'
        'image/tiff'
      when '.gif'
        'image/gif'
      when '.jpg'
        'image/jpeg'
      when '.jpeg'
        'image/jpeg'
      when '.pdf'
        'application/pdf'
      end
    end

    def normalize_date(date)
      date = date.tr('?', '')
      if date =~ / [0-9]+,/ && date != /-/
        date = Time.parse(date).to_date.to_s
      end
      date
    end

    def store_gf(rh, page, path)
      @generic_file = nil
      @generic_file = GenericFile.where(
        'title_sim' => unescape_and_clean(rh['title'])).where(
          Solrizer.solr_name('page_number') => page).first

      if @generic_file.blank?
        @generic_file = GenericFile.create! do |f|
          f.apply_depositor_metadata(@current_user.user_key)
          f.label = File.basename(path)
          time_in_utc = DateTime.now.new_offset(0)
          f.date_uploaded = time_in_utc
          f.date_modified = time_in_utc
          f.add_file(File.open(path), path: 'content', original_name: f.label,
                     mime_type: mime_type(File.extname(path)))
        end
        @generic_file.record_version_committer(@current_user)
        @generic_file.creator = ['Galter Health Sciences Library']
        @generic_file.title = [unescape_and_clean(rh['title'])]
      end

      binding.pry if @generic_file.title.first != unescape_and_clean(rh['title'])

      @generic_file.visibility = 'open'
      @generic_file.subject = rh['subject']
      @generic_file.mesh = rh['mesh']
      @generic_file.lcsh = rh['lcsh']
      @generic_file.subject_geographic = rh['geoname']
      @generic_file.subject_name = (rh['corpname'] || []) + (rh['persname'] || [])
      @generic_file.description = [rh['note']].compact
      @generic_file.date_created = [normalize_date(rh['create_date'])]
      @generic_file.abstract = [rh['abstract']].compact
      @generic_file.identifier = [rh['file_id']].compact
      @generic_file.rights = ['http://creativecommons.org/publicdomain/mark/1.0/']
      @generic_file.digital_origin = ['Reformatted Digital']
      @generic_file.page_number = page

      @generic_file.parent = rh['collection']
      @generic_file.save!
      Sufia.queue.push(CharacterizeJob.new(@generic_file.id))
      rh['collection'].members << @generic_file
      rh['collection'].save!
    end

    def container_parse(nset, parent_path)
      # Process the <c> aka <c0x> container elements.

      # params are a node set and the parent's path to digital
      # assets. The path is built from contextual data and may not be
      # quite a true path, but should match via some sort of regex
      # against the actual paths created by the Fx_file_info class.

      # We iterate over containers at a given level. For each
      # container we recurse to check that container's children for
      # more containers returning from recursion when a given
      # container has no container children. Iterate at each level,
      # recurse to deeper nesting.

      @break_set = false

      # Note: we modify @cn_loh in this method.

      cmatch = nset.children.to_s.match(/(?:<c\d+)|(?:<c(?:(?:\s+)|(?:>)))/is)

      if cmatch.nil?

        # No child containers, so we must be a leaf container aka we
        # describe individual items.

        # If we are a leaf, return true and we will process
        # ourself. The recursive call to content_parse() is checking
        # our children.

        # printf "Leaf container: %s\n", nset.name # nset[0].name

        return true
      else
        # print "cm: #{cmatch.inspect}\n"
      end

      have_c_children = false;
      nset.children.each_with_index { |ele,xx|
        #debug
        if @debug && (xx > 5 || @break_set)
          print "dev testing break after 30 containers\n"
          @break_set = true
          break
        end
        
        rh = Hash.new()

        # Is the current element a <c> container?

        # Use non-capturing zero width assertion to be a bit more
        # efficient, and to clarify our intention to match but not
        # capture, and to clarify that (?:) is for alternation.

        if ele.name.match(/(?:^c\d+)|(?:^c$)/i)

          have_c_children = true

          rh['pid'] = gen_pid()
          rh['ef_create_date'] = String.new(@ef_create_date.to_s)
          rh['is_container'] = true
          rh['type_of_resource'] = 'container="yes"'
          rh['parent_pid'] =  String.new(@cn_loh.last['pid'].to_s)

          # container id (attr), container level (attr),
          # container (element, c01, c02, ...), unittitle, container
          # type (attr), container (value, string, could be "6-7"), may be
          # multiple <container> elements), unitdate, scopecontent

          # Hull containers are <c> only, no matter the nesting depth.

          rh['container_element'] = String.new(ele.name.to_s)
          rh['container_level'] = String.new(ele.attribute('level').to_s)
          rh['container_id'] = String.new(ele.attribute('id').to_s)
          rh['type_of_resource'] = String.new(rh['container_level'].to_s)
          rh['type'] = String.new(rh['container_level'].to_s)
          rh['id'] = String.new(rh['container_id'].to_s)
          rh['creator'] = "See collection object #{@top_pid}"
          rh['corp_name'] = "See collection object #{@top_pid}"
          rh['object_type'] = String.new(rh['container_element'].to_s)
          rh['set_type'] = "container"
          rh['project'] = String.new(@top_project.to_s)

          # Note: container_type and container_value need to be a list
          # of hash due to possible multiple values!
          
          # These seem to work too for Tobin, Cheuse and others with
          # <c0x> but would fail with Hull <c>. When the work, they
          # return the expected single value or nil when there isn't a
          # unitdate.

          # nset.xpath("./#{@ns}c02/#{@ns}c03/#{@ns}did").children.xpath("./#{@ns}unitdate")[0]

          # nset.xpath("./#{@ns}c02/#{@ns}c03/#{@ns}did")[0].xpath("./#{@ns}unitdate")[0]
          
          # Default values.

          rh['container_unitdate'] = ""
          rh['container_unittitle'] = ""
          rh['container_unitid'] = ""
          rh['path_key'] = ""

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

                # It seems best to simply hard code the path_key for
                # each case. They don't easily generalize and a
                # general solution won't be robust.
                if Path_key_name == 'tobin'
                  rh['path_key'] = String.new(rh['container_unitid'].to_s)
                end
              end

              if child.name.match(/unittitle/)
                
                # Don't use .gsub! because if it does nothing, it
                # returns nil rather than the expected returning the
                # input string. In other words, it only returns the
                # input string if it changes it.

                rh['container_unittitle'] = child.content.strip.gsub(/\s+/," ")

                # It seems best to simply hard code the path_key for
                # each case. They don't easily generalize and a
                # general solution won't be robust.
                if Path_key_name == 'hull'
                  rh['path_key'] = String.new(rh['container_unittitle'].to_s)
                end
              end

              if child.name.match(/dao/)
                begin
                  rh['href'] = child.attribute('href').value
                  rh['file_id'] = query_from_url(rh['href'])
                  if rh['file_id'].blank?
                    rh['file_id'] = rh['container_unitid']
                  end
                  raise if rh['file_id'].blank?
                  rh['fname'] = find_file(rh['file_id'], rh)
                rescue
                  puts "Can't file file_id for #{rh['title']}"
                end
              end

              if child.name.match(/note/)
                rh['note'] = unescape_and_clean(child.content, '.')
              end

              if child.name.match(/abstract/)
                rh['abstract'] = unescape_and_clean(child.content, '.')
              end
            }
          end

          ele.xpath("./#{@ns}controlaccess").each {|ca|
            ca.children.each { |child|
              if child.name.match(/subject/)
                unless subject = child.attributes['source'].try(:value)
                  byebug
                end
                rh[subject] = [] if rh[subject].nil?
                rh[subject].concat(child.content.strip.gsub(/\s+/," ").split(',')).flatten.compact
              end

              if child.name.match(/geogname/)
                rh['geoname'] = [] if rh['geoname'].nil?
                rh['geoname'] << child.content.strip.gsub(/\s+/," ")
                rh['geoname'].flatten.compact
              end

              if child.name.match(/corpname/)
                rh['corpname'] = [] if rh['corpname'].nil?
                rh['corpname'] << child.content.strip.gsub(/\s+/," ")
                rh['corpname'].flatten.compact
              end

              if child.name.match(/persname/)
                rh['persname'] = [] if rh['persname'].nil?
                rh['persname'] << child.content.strip.gsub(/\s+/," ")
                rh['persname'].flatten.compact
              end
            }
          }

          # This is espeically true for Hull which does not have
          # unique id attribute for each <c>, but does have a unique
          # <c><unitid>.

          if rh['id'].empty?
            rh['id'] = String.new(rh['container_unitid'].to_s)
          end

          rh['create_date'] = String.new(rh['container_unitdate'].to_s).tr('()', '')

          # Build the description and title to be more consistent
          # between collection, containers, etc.

          rh['title'] = ""
          
          # Change line below from rh['container_id'] to rh['id'] which has logic
          # to give is a rational value. See comment above.

          details = "Container: #{rh['container_element']} id:#{rh['id']} level:#{rh['container_level']}"

          if ! rh['container_unittitle'].to_s.empty?
            rh['title'] = "#{rh['container_unittitle']} "
            rh['description'] = "Title: #{rh['title']} #{details}"
          else
            rh['title'] = String.new(details.to_s)
            rh['description'] = String.new(details.to_s)
          end


          # If the current node is a top level container node then get
          # the scopecontent. If it is not nil look at the children
          # and pull content out of any p elements. Remember that (at
          # least in the nokogiri universe) there are invisible text
          # elements around all other elements.

          rh['container_scope'] = ""

          # Old code looked for c01 as top level containers. 
          #if ele.name.match(/c01/) 

          # New code looks for a container with a dsc parent.

          if ele.parent.name.match(/dsc/)
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
          rh['scope'] = String.new(rh['container_scope'].to_s)

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
          # rh['project'] = String.new(rh['title'].to_s)

          # The content() method of Nokogiri returns &amp; and similar
          # entities as ascii equivalents which causes problems when we put
          # the content back into XML. Escape everything.
          
          prep_data(rh)

          if Path_key_name == 'hull'
            curr_path = "#{parent_path}/#{rh['path_key']}"
          elsif Path_key_name == 'gvblack'
            rh['path_key'] = gvblack_path_key(binding)
          else
            curr_path = "#{rh['path_key']}"
          end

          rh['contentmeta'] = ""

          store_collection(rh)
          # Order critical. Push our data onto @cn_loh, then
          # recurse. After we return from recursing, ingest ourself.
          # A true return value from container_parse() means there
          # are no children so we are an ITEM/FILE node. 

          # We only process file data if this has no child
          # containers. Tobin collection unitid has the directory name
          # that contains the files. Hull uses the unittitle as
          # directory or file depending on context.

          @cn_loh.push(rh)

          # If container_parse() doesn't find any container children,
          # then it returns true meaning 'I am a leaf' thus leaf_flag
          # becomes true.

          # *************** important ****************
          # This is where container_parse() recurses to process container children.

          leaf_flag = container_parse(ele, curr_path)

          # Any changes to rh[] below this line will not be available
          # to our children. That is fine as things are now, but don't
          # add any rh[] keys below this line that are necessary to
          # children of the current node (ele).

          # Side effect warning: we'll use rh['cm'].size > 0 to mean
          # that this EAD container has files and we need to create
          # file objects.

          rh['cm'] = []

          if leaf_flag and ! rh['path_key'].empty?

            # Create a list rh['cm'] that is a list of hash of
            # technical meta data for the files (digital assets) in
            # the assets directory aka the files described by this container
            # <c> or <c0x> element.

            # A list of files that (may) exist in the file system. If
            # the list is size>0 then we have files.

            if Path_key_name == 'hull'
              rh['cm'] = @fi_h.discover(curr_path)
            elsif Path_key_name == 'gvblack'
              #rh['cm'] = @fi_h.gvblackthing(curr_path)
            else
              rh['cm'] = @fi_h.get(curr_path)
            end

            if rh['cm'].size > 0
              printf "Found group: %s size: %s\n", curr_path, rh['cm'].size
              #create_file_objects(rh)
            end
          else
            # printf "lf: %s pk: %s title: %s\n", leaf_flag, curr_path, rh['path_key'], rh['container_unittitle']
          end

          # Important concept: we don't want to render our own foXML
          # until our children are finished rendering. Children are
          # rendered when content_parse() recurses (above), so the
          # call to result() and write_foxml() must come after
          # content_parse(). Siblings are rendered in the order in
          # which they occur in the EAD, naturally.

          @xml_out = @generic_template.result(binding())
          wfx_name = write_foxml(rh)

          if rh['type'].empty?
            if !rh['href']
              p = nil
              fid = 'asdfasdfasdfasdfasdf'
              if rh['title'] =~ /Portrait of G.V. Black./
                fid = 'portrait.tif'
              elsif rh['title'] =~ /G.V. Black statue in Lincoln Park/
                fid = 'lincolnpkstat_1.tif'
              elsif rh['title'] =~ /G.V. Black as a teacher/
                fid = 'teacher.tif'
              elsif rh['title'] =~ /G.V. Black as a scientist/
                fid = 'scientist.tif'
              elsif rh['title'] =~ /G.V. Black as an administrator/
                fid = 'administrator.tif'
              elsif rh['title'] =~ /Black and colleagues/
                fid = 'colleague.tif'
              elsif rh['title'] =~ /outdoorsman./
                fid = 'outdoorsman.tif'
              elsif rh['title'] =~ /Great Dental Clinic/
                fid = 'gvblackinoperatory.tif'
              elsif rh['title'] =~ /Group photograph/
                fid = 'wcdc_group.jpg'
                p = Digital_assets_home
              end

              if @cn_loh[-2]['title'] =~ /Series IV/
                p = Digital_assets_home + '/Photographs'
              end

              if p
                Find.find(p) do |path|
                  if path.downcase =~ /.*#{fid}/
                    rh['fname'] = path
                  end
                end
              end
            end
            if rh['fname']
              rh['type'] = 'item'
              store_collection(rh)
              make_file(rh)
              puts "Processed #{rh['title']}: #{rh['fname']}"
            else
              puts "No file for #{rh['title']}"
            end
          end


          #print "Wrote foxml: #{wfx_name} pid: #{rh['pid']} id: #{rh['id']}\n"

          # Actions to implment here: Pop stack. When we eventually
          # implement "isParentOf" then this is where we will modify the
          # Fedora object created above to know about all the children
          # created during the recursion.

          @cn_loh.pop()
        end
      }

      # We finished processing which means that we recursed which
      # means we have children which means we are not a
      # leaf. In other words, leaf_flag is false so return false.
      
      # The "have no children" case where we return true is at the top
      # of the method.
      
      return have_c_children

    end # container_parse

    def gvblack_path_key(container_obj)
      return []
      unless attribs.find {|a| a[1] =~ /image not available/ }
        query = query_from_url(attribs.find {|a| a[0] == 'url' }.second)
      end
      if query.blank?
        query = attribs.find {|a| a[0] =~ /Accession/}.try(:second).try(:downcase)
      end
      find_directory_path(query)
    end

    def find_directory_path(query)
      paths
    end

    def collection_parse(rh)
      
      # Not used currently, but could be later.
      ead_schema_ns = 'urn:isbn:1-931666-22-9'
      
      # Agnostic variables. This is OOP so it is ok to use instance vars
      # because they won't cause any of the bugs that arise from using
      # globals in imperative code. Obi Wan says: These aren't the
      # globals you're looking for.
      
      # Interestingly, titleproper can occur in at least two places,
      # so only use the first [0]th instance.

      tmp = @xml.xpath("//*/#{@ns}titleproper[@type='formal']")[0]
      if ! tmp.nil?
        rh['titleproper'] = String.new(tmp.content.to_s)
      else
        # printf "tp: %s ns:\n", @xml.xpath("//*/#{@ns}titleproper"), @xml.inspect
        rh['titleproper'] = @xml.xpath("//*/#{@ns}titleproper")[0].content
      end
      
      rh['title'] = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}unittitle")[0].content

      rh['creator'] = ""

      begin
        @xml.xpath("//*/#{@ns}origination[contains(translate(@label,'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'creator')]/#{@ns}persname")[0].content
      rescue NameError => err
        # If there was an error we don't really care why, but print a message regardless.
        print "Warning: Cannot get <origination><persname>\n"
      end

      rh['id'] = @xml.xpath("//*/#{@ns}archdesc/#{@ns}did/#{@ns}unitid")[0].content

      rh['description'] = "Title: #{rh['title']} Collection: #{rh['id']}"
      
      # Ignore <head>. Get all <p> and separate by \n -->
      
      # Tween always at the beginning of the accumulator output
      # string. Init tween to "" and change to the tween string after
      # the first iteration (and ever iteration which may seem
      # wasteful, but saves an if statement). No knowing what this
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
        rh['set_type'] = String.new(rh['type'].to_s)
      end
      
      rh['agreement_id'] = ""
      rh['project'] = String.new(rh['title'].to_s)
      
      # The content() method of Nokogiri returns &amp; and similar
      # entities as ascii equivalents which causes problems when we put
      # the content back into XML. Escape everything.

      prep_data(rh)

    end # collection_parse
    
    
    def write_foxml(rh)
    end

    def write_foxml_old(pid)

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

      #working_url = "#{@base_url}/objects/nextPID?namespace=#{@pid_namespace}&format=xml"
      #some_xml = RestClient.post(working_url, '')
      #numeric_pid = some_xml.match(/<pid>#{@pid_namespace}:(\d+)<\/pid>/)[1]

      # Fedora requires pids to match a regex, apparently text:number

      return "sufia:#{Random.rand(9999999)}"
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

      # Do things to data that are universal for all content.

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
    end # def prep_data
  end # Class Fx_maker


  class Proc_sql

    # Process (chew) sql records into a list of hash. Called in an
    # execute2() loop. Ruby doesn't really know how to return SQL results
    # as a list of hash, so we need this helper method to create a
    # list-of-hash. You'll see Proc_sql all over where we pull back some
    # data and send that data off to a Rails erb to be looped through,
    # usually as table tr tags.
    
    def initialize
      @columns = []
      @loh = []
    end

    def loh
      if (@loh.length>0)
        return @loh
      else
        return [{'msg' => "n/a", 'date' => 'now'}];
      end
    end

    # Initially I thought I was sending this an array from db.execute2
    # which sends the row names as the first record. However, using
    # db.prepare we use stmt.execute (there is no execute2 for
    # statements), so we're getting a ResultSet on which we'll use the
    # columns() method to get column names.

    # It makes sense to each through the result set here. The calling
    # code is cleaner.

    def chew(rset)
      if (@columns.length == 0 )
        @columns = rset.columns;
      end
      rset.each { |row|
        rh = Hash.new();
        @columns.each_index { |xx|
          rh[@columns[xx]] = row[xx];
        }
        @loh.push(rh);
      }
    end
  end # class Proc_sql

end
