module MmEsSearch
  module Api
    module Query
      
      class QueryFilter < AbstractQuery
        plugin AbstractFilter
        
        one :query, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        key :cache, Boolean
        
        def to_mongo_query
          query.to_mongo_query
        end
        
        def to_es_query
          query_params = {
            :query => query.to_es_query
          }
          query_params[:_cache] = cache unless cache.nil?
          {:fquery => query_params}
        end
        
        
      end
      
    end
  end
end
