#!/usr/bin/ruby2.2

require 'net/http'
require 'mongoid'
require_relative 'library.rb'
require_relative 'utils.rb'
require_relative 'install_script.rb'

Mongoid.load!('./mongoid.yml', :production)
Processing::Library.create_indexes #since we aren't using rake or rails.

full_text = Net::HTTP.get 'download.processing.org', '/contribs'

lib_list = full_text.split /^\s*library\s*$/
lib_list.shift

libraries = []

lib_list.each do |lib_text|
    library = Processing::Library.new
    props = lib_text.split "\n"
    props.each do |prop|
        key_value_pair = prop.split "="
        key = key_value_pair[0]
        value = key_value_pair[1]
        if key == 'name'
            library.name = value if key == 'name'
            library.normalized_name = Processing::Utils.normalize_name value
        end
        library.version = value if key == 'version'
        library.pretty_version = value if key == 'prettyVersion'
        library.download = value if key == 'download'

        # if Processing::Library.where(normalized_name: library.normalized_name, pretty_version: library.pretty_version).empty? == true
        #     library.save
        # end
    end
    begin
        library.save!
    rescue Exception => e
        if e.message.include? 'duplicate key error' #library already exists
            library.delete
        end
    end
end

libraries = Processing::Library.all

libraries.each do |lib|
    puts "#{lib.name}: #{lib.normalized_name}"
end

Processing::InstallScript.new.create libraries
