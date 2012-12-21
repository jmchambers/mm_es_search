module MmEsSearch
  module Api
    module Query
      
      class HasParentQuery < AbstractQuery
        
        key :parent_type, Symbol
        one :query, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        key :scope, String
        
        def to_mongo_query(options = {})
          raise NotImplementedError
        end
        
        def to_es_query
          params = {:parent_type => parent_type, :query => query.to_es_query}
          params[:_scope] = scope if scope?
          {:has_parent => params}
        end
        
      end
      
    end
  end
end
