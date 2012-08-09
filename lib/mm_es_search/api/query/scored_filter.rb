module MmEsSearch
  module Api
    module Query
      
      class ScoredFilter
        
        include MongoMapper::EmbeddedDocument
        plugin  MmUsesNoId
        
        one :filter, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        key :boost,  Float
        key :script, String
        
        def to_mongo_query
          filter.to_mongo_query
        end
        
        def to_es_query
          filter_params = attributes.except('filter', '_type')
          filter_params[:filter] = filter.to_es_query
          filter_params
        end
        
        
      end
      
    end
  end
end