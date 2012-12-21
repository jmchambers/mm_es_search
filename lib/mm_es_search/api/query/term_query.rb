module MmEsSearch
  module Api
    module Query
      
      class TermQuery < AbstractQuery
        
        key :field, String
        key :path, String
        
        key :value #string or number
        key :boost, Float
        
        def to_mongo_query(options = {})
          
          if options[:negated]
            {mongo_abs_field => {'$ne' => value}}
          else
            {mongo_abs_field => value}
          end
        end
        
        def to_es_query
          if boost
            {:term => {es_abs_field => {:value => value, :boost => boost}}} 
          else
            {:term => {es_abs_field => value}}
          end
        end
        
      end
      
    end
  end
end
