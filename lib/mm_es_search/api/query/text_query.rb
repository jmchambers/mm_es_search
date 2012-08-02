module MmEsSearch
  module API
    module Query
      
      class TextQuery < AbstractQuery
        
        key :field, String
        key :query, String
        key :operator, String
        key :analyzer, String
        
        key :fuzziness, Float
        key :prefix_length, Integer
        key :max_expansions, Integer

        key :type, String#, :default => "phrase_prefix"
        key :slop, Integer
        key :boost, Float
        
        
        def print_foo
          puts 'foo'
        end
        
        def to_mongo_query(options = {})
          
          raise "TextQuery doesn't support mongo execution"
          
        end
        
        def to_es_query
  
          return {:text => {field => self.attributes.except("_type", "field")}}

        end
        
      end
      
    end
  end
end
