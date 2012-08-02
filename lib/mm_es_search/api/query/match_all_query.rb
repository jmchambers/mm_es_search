module MmEsSearch
  module API
    module Query
      
      class MatchAllQuery < AbstractQuery
        
        def to_mongo_query(options = {})
          return {}
        end
        
        def to_es_query
          return {:match_all => {}}
        end
        
      end
      
    end
  end
end
