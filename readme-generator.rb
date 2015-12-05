require 'liquid'

module Processing
    class ReadmeGenerator
        def initialize(readme_path)
            @readme_path = readme_path
        end

        def generate(libraries)
            liquid_libraries = libraries.map { |lib| Processing::LiquidLibrary.new(lib) }
            template = Liquid::Template.parse(IO.read('readme.liquid'))
            IO.write(@readme_path, template.render('libraries' => liquid_libraries))
        end
    end
end
