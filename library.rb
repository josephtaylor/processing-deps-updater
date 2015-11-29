module Processing
    class Library
        include Mongoid::Document
        field :download, type: String
        field :name, type: String
        field :normalized_name, type: String
        field :pretty_version, type: String
        field :version, type: Integer

        index({ normalized_name: 1, pretty_version: 1}, { unique: true})
    end
end
