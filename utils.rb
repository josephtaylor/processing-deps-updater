module Processing
    class Utils
        def self.normalize_name(name)
            unless name
                return name
            end
            name = name.sub /^\W/, ''
            name = name.sub /\W+$/, ''
            name = name.gsub /\W+/, '_'
            name[0] = name[0].downcase
            name
        end
    end
end
