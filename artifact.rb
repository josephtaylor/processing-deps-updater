require 'rubygems'
require 'net/http'
require 'zip'
require 'fileutils'
require 'fuzzystringmatch'

module Processing
    class Artifact
        def initialize(processing_deps_path)
            @processing_deps_path = processing_deps_path
            @jarow = FuzzyStringMatch::JaroWinkler.create(:native)
        end

        def create(library)
            begin
                directory = "#{@processing_deps_path}/#{library.normalized_name}/#{library.pretty_version}"
                if Dir.exist? directory
                    puts "Library #{library.name} - version: #{library.pretty_version} has already been synced."
                    return
                end

                FileUtils.mkdir_p directory
                puts "Directory created: #{directory}"

                zip_file_path = download(directory, library)
                puts "Zip file downloaded: #{zip_file_path}"

                extract(directory, zip_file_path)

                remove_macosx_folders directory

                FileUtils.rm_f zip_file_path, :verbose => true

                jar_path = find_jar_path(directory)
                unless File.exist? jar_path
                    puts "Jar file path: #{jar_path}"
                    raise 'Jar File is not named correctly.'
                end
                clean_up directory
                jar_path
            rescue Exception => e
                puts "Something failed while processing #{library.name}"
                puts e.message
                puts e.backtrace.inspect
                ''
            end
        end

        def download(directory, library)
            zip_name = library.download.split('/').last
            full_path = "#{directory}/#{zip_name}"
            Dir.chdir directory do
                `wget #{library.download}`
            end
            full_path
        end

        def extract(directory, zip_file_path)
            unless File.exist? zip_file_path
                raise "Zip file download failed for #{zip_file_path}"
            end
            Zip::File.open(zip_file_path) do |zip_file|
                zip_file.each do |f|
                    f_path=File.join(directory, f.name)
                    FileUtils.mkdir_p(File.dirname(f_path))
                    puts "\tExtracting file: #{f_path}"
                    zip_file.extract(f, f_path) unless File.exist?(f_path)
                end
            end
        end

        def find_jar_path(directory)
            extracted_folder = Dir.entries(directory).reject { |d| d.include?('.zip') || d.include?('.txt') }.sort.last
            puts "Unzipped folder: #{extracted_folder}"
            # hack for punktiert to work (remove if library zip gets fixed)
            if extracted_folder == 'punktiert'
                library_folder = File.join(directory, extracted_folder, extracted_folder, 'library')
            else
                library_folder = File.join(directory, extracted_folder, 'library')
            end

            puts "Determined library path: #{library_folder}"
            jar_files = Dir.entries(library_folder).select { |f| f.match /.*\.jar$/ }
            puts "Available jar files: #{jar_files}"
            if jar_files.length == 1
                puts "Only one jar file, using: #{jar_files[0]}"
                return File.join(library_folder, jar_files[0])
            end
            the_jar_file = ''
            jar_files.each do |jar_file|
                name = jar_file.gsub('.jar', '')
                if @jarow.getDistance(name, extracted_folder) > 0.5
                    puts "Fuzzy Match Found: #{jar_file}"
                    the_jar_file = jar_file
                    break
                end
            end
            raise "No candidate jar file identified for #{extracted_folder}" if the_jar_file == ''
            File.join(library_folder, the_jar_file)
        end

        def clean_up(directory)
            base_dir = File.join(directory, Dir.entries(directory).sort.last)
            FileUtils.rm_rf "#{base_dir}/examples", :verbose => true
            FileUtils.rm_rf "#{base_dir}/reference", :verbose => true
            FileUtils.rm_rf "#{base_dir}/src", :verbose => true
        end

        def remove_macosx_folders(directory)
            mac_folder = "#{directory}/__MACOSX"
            if Dir.exist? mac_folder
                FileUtils.rm_rf mac_folder, :verbose => true
            end
        end
    end
end
