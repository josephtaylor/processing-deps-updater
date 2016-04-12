#!/usr/bin/ruby2.2

require 'net/http'
require 'json'
require 'data_mapper'
require_relative 'artifact.rb'
require_relative 'library.rb'
require_relative 'utils.rb'
require_relative 'install_script.rb'
require_relative 'readme-generator.rb'

# TODO: Make this configurable
processing_deps_path = '/opt/dev/processing-deps'

config = JSON.parse(IO.read('database.json'))

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, config['database_connection'])
DataMapper.finalize
DataMapper.auto_upgrade!

full_text = Net::HTTP.get 'download.processing.org', '/contribs'

lib_list = full_text.split /^\s*library\s*$/
lib_list.shift

lib_list.each do |lib_text|
    library = Processing::Library.new
    library.id = SecureRandom.uuid
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
        library.type = value if key == 'type'
    end
    # skip modes, examples, and tools
    next unless library.type == 'library'

    if library.pretty_version.to_s.strip == ''
        library.pretty_version = library.version
    end

    begin
        puts "Saving: #{library.name}"
        unless library.save
            library.errors.each { |e| puts e }
        end
    rescue Exception => e
        puts "Failed to save #{library.name}: #{e.message}"
    end
end

libraries = Processing::Library.all

install_script = Processing::InstallScript.new processing_deps_path, 'install.sh'

libraries.each do |lib|
    jar_file = Processing::Artifact.new(processing_deps_path).create(lib)
    unless jar_file.to_s == ''
        puts "Updating library with jar_file: #{jar_file}"
        lib.jar_file = jar_file
        lib.save
    end
    install_script.add_library lib
end

install_script.add_processing_version '2.2.1'
install_script.add_processing_version '3.0'
install_script.add_processing_version '3.0b4'
install_script.close

Processing::ReadmeGenerator.new("#{processing_deps_path}/README.md").generate(libraries)
