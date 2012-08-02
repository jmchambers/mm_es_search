class AbstractSortModel
  
  include MmEsSearch::API::Sort
  include MongoMapper::EmbeddedDocument
  plugin MmUsesNoId
  
  key :direction, String # "asc"* | "desc"
  
end
