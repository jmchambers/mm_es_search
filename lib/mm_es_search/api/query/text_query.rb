module MmEsSearch
  module Api
    module Query
      
      class TextQuery < AbstractQuery
        
        key :field, String
        key :path,  String
        
        key :query, String
        key :operator, String
        key :analyzer, String
        
        key :fuzziness, Float
        key :prefix_length, Integer
        key :max_expansions, Integer

        key :type, String#, :default => "phrase_prefix"
        key :slop, Integer
        key :boost, Float
                
        def to_mongo_query(options = {})
          
          raise "TextQuery doesn't support mongo execution"
          
        end
        
        def to_es_query
  
          params = self.attributes.except("_type", "field", "path")
          field  = self.field
          field  = "#{path}.#{field}" if path
          
          return {:text => {field => params}}

        end
        
      end
      
    end
  end
end
