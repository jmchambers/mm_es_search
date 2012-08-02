module MmEsSearch
  module API
    module Query
      
      class CustomScoreQuery < AbstractQuery
      
        one :query, :class_name => 'MmEsSearch::API::Query::AbstractQuery'
        key :script, String
      
        def to_mongo_query(options = {})
          
          return query.to_mongo_query(options)
          
        end
        
        def to_es_query
          
          custom_score_params = {
            :query => query.to_es_query,
            :script => script
          }
      
          return {:custom_score => custom_score_params}
          
        end
        
      end
      
    end
  end
end
