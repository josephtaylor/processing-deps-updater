module Processing
    class InstallScript
        def initialize(processing_deps_path, file)
            @file = File.open "#{processing_deps_path}/#{file}", 'w'
            @file.write "#!/bin/sh\n"
            @processing_deps_path = processing_deps_path
        end

        def add_library(lib)
            if lib.jar_file.to_s == ''
                puts "No jar file found for #{lib.name}"
                return
            end
            @file.write 'mvn install:install-file'
            @file.write " -DgroupId=#{lib.normalized_name}"
            @file.write " -DartifactId=#{lib.normalized_name}"
            @file.write " -Dversion=#{lib.pretty_version}"
            @file.write " -Dpackaging=jar -Dfile=#{lib.jar_file.gsub(@processing_deps_path, '.')}\n\n"
        end

        def add_processing_version(version)
            @file.write 'mvn install:install-file'
            @file.write " -DgroupId=org.processing"
            @file.write " -DartifactId=processing-core"
            @file.write " -Dversion=#{version}"
            @file.write " -Dpackaging=jar -Dfile=./processing/#{version}/core.jar\n\n"
        end

        def close
            @file.close
        end
    end
end
