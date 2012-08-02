module MmEsSearch
  module Api
    module Query
      
      class ConstantScoreQuery < AbstractQuery
      
        one :query, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        key :boost, Integer
      
        def to_mongo_query(options = {})
          
          return query.to_mongo_query(options)
          
        end
        
        def to_es_query
          
          constant_score_params = {
            :query => query.to_es_query
          }
          constant_score_params.merge!(:boost => boost) if boost?
      
          return {:constant_score => constant_score_params}
          
        end
        
      end
      
    end
  end
end
