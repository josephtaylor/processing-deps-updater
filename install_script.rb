module Processing
    class InstallScript
        def initialize(location)
            @file = File.open location, 'w'
            @file.write "#!/bin/sh\n"
        end

        def add_library(lib, jar)
            @file.write 'mvn install:install-file'
            @file.write " -DgroupId=#{lib.normalized_name}"
            @file.write " -DartifactId=#{lib.normalized_name}"
            @file.write " -Dversion=#{lib.pretty_version}"
            @file.write " -Dpackaging=jar -Dfile=#{jar}\n\n"
        end

        def add_processing_version(version, processing_deps_path)
            @file.write 'mvn install:install-file'
            @file.write " -DgroupId=org.processing"
            @file.write " -DartifactId=processing-core"
            @file.write " -Dversion=#{version}"
            @file.write " -Dpackaging=jar -Dfile=#{processing_deps_path}/processing/#{version}/core.jar\n\n"
        end

        def close
            @file.close
        end
    end
end
