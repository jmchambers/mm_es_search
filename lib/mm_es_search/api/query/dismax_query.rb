module MmEsSearch
  module API
    module Query
      
      class DismaxQuery < AbstractQuery
      
        many :queries, :class_name => 'MmEsSearch::API::Query::AbstractQuery'
        key :tie_breaker, Float
        key :boost, Float

        def to_mongo_query(options = {})
          raise 'Dis Max Query cannot be run as a mongo query'
        end
        
        def to_es_query
          
          dismax_params = {:queries => queries.map(&:to_es_query)}
          dismax_params.merge!(:tie_breaker => tie_breaker) if tie_breaker?
          dismax_params.merge!(:boost => boost) if boost?
          
          return {:dis_max => dismax_params}
      
        end
      
      end
      
    end
  end
end
