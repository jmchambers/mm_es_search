class AbstractQueryModel
  
  include MmEsSearch::API::Query
  include MongoMapper::EmbeddedDocument
  plugin  MmUsesNoId
  
  def to_query
    
  end

  def to_filter
    
  end
    
end
