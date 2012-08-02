module MmEsSearch
  module API
    module Query
      
      class QueryStringQuery < AbstractQuery
        
        key :query, String
        key :default_field, String
        key :boost, Float
        key :default_operator, String
        key :analyzer, String
        key :allow_leading_wildcard, Boolean
        key :lowercase_expanded_terms, Boolean
        key :enable_position_increments, Boolean
        key :fuzzy_prefix_length, Integer
        key :fuzzy_min_sim, Float
        key :phrase_slop, Integer
        key :analyze_wildcard, Boolean
        key :auto_generate_phrase_queries, Boolean
        
        def to_mongo_query(options = {})
          
          raise "QueryStringQuery doesn't support mongo execution"
          
        end
        
        def to_es_query
  
          return {:query_string => self.attributes.except("_type")}

        end
        
      end
      
    end
  end
end
