require 'rubygems'
require 'net/http'
require 'zip'
require 'fileutils'

module Processing
    class Artifact
        def initialize(processing_deps_path, install_script)
            @processing_deps_path = processing_deps_path
            @install_script = install_script
        end

        def create(library)
            begin
                directory = "#{@processing_deps_path}/#{library.normalized_name}/#{library.pretty_version}"
                return if Dir.exist? directory
                FileUtils.mkdir_p directory
                zip_file_path = download(directory, library)
                extract(directory, zip_file_path)
                jar_path = find_jar_path(zip_file_path)
                unless File.exist? jar_path
                    puts "Jar file path: #{jar_path}"
                    raise 'Jar File is not named correctly.'
                end
                @install_script.add_library(library, jar_path)
            rescue Exception => e
                puts "Something failed while processing #{library.name}"
                puts e.message
                puts e.backtrace.inspect
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
                    zip_file.extract(f, f_path) unless File.exist?(f_path)
                end
            end
        end

        def find_jar_path(zip_file_path)
            _, zip_name, _ = zip_file_path.match(/(.*\/)(.*)\.zip/).captures
            "#{zip_file_path.gsub('.zip', '')}/library/#{zip_name}.jar"
        end
    end
end
