module MmEsSearch
  module Api
    module Query
      
      class PrefixQuery < AbstractQuery
        
        key :field, String
        key :path, String
        
        key :value, String
        key :boost, Float
        
        def to_mongo_query(options = {})
          prefix_regex = /^#{value}/
          if options[:negated]
            {mongo_abs_field => {'$ne' => prefix_regex}}
          else
            {mongo_abs_field => prefix_regex}
          end
        end
        
        def to_es_query
          if boost
            {:prefix => {es_abs_field => {:value => value, :boost => boost}}} 
          else
            {:prefix => {es_abs_field => value}}
          end
        end
        
      end
      
    end
  end
end
