module MmEsSearch
  module Api
    module Query
      
      class FilteredQuery < AbstractQuery
        
        one :query, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        one :filter, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        
        def to_mongo_query(options = {})
          if query.is_a?(MatchAllQuery) or query.nil?
            filter.to_mongo_query(options)
          else
            AndFilter.new(:filters => [query, filter]).to_mongo_query(options)
          end
        end
        
        def to_es_query
          if query.is_a?(MatchAllQuery) or query.nil?
            {:filtered => {:query => MatchAllQuery.new.to_es_query, :filter => filter.to_es_query}}
          else
            {:filtered => {:query => query.to_es_query, :filter => filter.to_es_query}}
          end
        end
        
      end
      
    end
  end
end
