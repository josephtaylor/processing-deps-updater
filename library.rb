require 'liquid'

module Processing
    class Library
        include DataMapper::Resource
        property :id, UUID, :key => true
        property :download, String, :length => 255
        property :name, String, :length => 255
        property :normalized_name, String, :length => 255, :unique_index => :name_version
        property :pretty_version, String, :length => 255, :unique_index => :name_version
        property :version, Integer
    end

    class LiquidLibrary < Liquid::Drop
        def initialize(library)
            @library = library
        end

        def name
            @library.name
        end

        def normalized_name
            @library.normalized_name
        end

        def pretty_version
            @library.pretty_version
        end
    end
end
