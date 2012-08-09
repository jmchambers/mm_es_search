module MmEsSearch
  module Api
    module Query
      
      class CustomFiltersScoreQuery < AbstractQuery
        
        one  :query,          :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        many :scored_filters, :class_name => 'MmEsSearch::Api::Query::ScoredFilter'
        key  :score_mode,     Symbol
        
        def to_mongo_query(options = {})
          query = self.query.is_a?(MatchAllQuery) ? nil : self.query
          filters = (scored_filters.map(&:filter) << query).compact
          AndFilter.new(:filters => filters).to_mongo_query(options)
        end
        
        def to_es_query
          query_params = {
            :query   => query.to_es_query,
            :filters => scored_filters.map(&:to_es_query)
          }
          query_params[:score_mode] = score_mode unless score_mode.nil?
          {:custom_filters_score => query_params}
        end

      end
      
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