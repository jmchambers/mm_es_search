module MmEsSearch
  module Models
    class AbstractSortModel
      
      include MmEsSearch::Api::Sort
      include MongoMapper::EmbeddedDocument
      plugin  MmUsesNoId
      
      key :direction, String # "asc"* | "desc"
      
    end
  end
end
