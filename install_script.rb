module Processing
    class InstallScript
        def create(libraries)
            begin
                file = File.open '../test.sh', 'w'
                file.write "#!/bin/sh\n"
                libraries.each do |lib|
                    file.write 'mvn install:install-file'
                    file.write " -DgroupId=#{lib.normalized_name}"
                    file.write " -DartifactId=#{lib.normalized_name}"
                    file.write " -Dversion=#{lib.pretty_version}"
                    file.write " -Dpackaging=jar -Dfile=2.2.1/core.jar\n\n"
                end
            ensure
                file.close
            end
        end
    end
end
