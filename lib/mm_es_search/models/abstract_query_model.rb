module MmEsSearch
  module Models

    class AbstractQueryModel
      
      include MmEsSearch::Api::Query
      include MongoMapper::EmbeddedDocument
      plugin  MmUsesNoId
      
      def to_query
        
      end
    
      def to_filter
        
      end
        
    end

  end 
end
