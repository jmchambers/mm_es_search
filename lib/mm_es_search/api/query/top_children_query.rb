module MmEsSearch
  module Api
    module Query
            
      class TopChildrenQuery < AbstractQuery
      
        one :query, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        key :type,                String
        key :score,               String
        key :_scope,              String
        key :factor,              Fixnum
        key :incremental_factor,  Fixnum
        
        def to_mongo_query(options = {})
          
        end
        
        def to_es_query
          query_params = attributes.except('query', '_type')
          query_params[:query] = query.to_es_query
          {:top_children => query_params} 
        end
        
      end
        
    end
  end
end
