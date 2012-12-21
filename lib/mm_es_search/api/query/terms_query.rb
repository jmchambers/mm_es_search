module MmEsSearch
  module Api
    module Query
      
      class TermsQuery < AbstractQuery
        
        key :field, String
        key :path, String
        
        key :terms, Array
        key :boost, Float
        
        key :execution, Symbol
        
        key :minimum_match, Integer
        
        def get_object_value(obj,path,field)
          method_arg_array = [path,field].join('.').split('.').map {|m| m =~ /^\d+$/ ? [:slice, m.to_i] : [m] }
          method_arg_array.inject(obj) {|obj, method_and_args| obj.send(*method_and_args)}
        end
        
        def run_analyzer(obj,path,field)
          #this just splits on whitespace, but we could have an instance variable store a reference to a more complex analyzer
          val = get_object_value(obj,path,field)
          case val
          when String
            val.split
          when Array
            val.flatten.join(' ').split
          end
        end

        def to_object_query
          return ->(obj){ (run_analyzer(obj,path,field) & terms).any? }
        end
        
        def to_mongo_query(options = {})
          
          if options[:negated]
            {mongo_abs_field => {'$nin' => terms}}
          else
            {mongo_abs_field => {'$in' => terms}}
          end
        end
        
        def to_es_query
          terms_params = {es_abs_field => terms}
          terms_params.merge!(:boost => boost) if boost?
          terms_params.merge!(:minimum_match => minimum_match) if minimum_match?
          terms_params.merge!(:execution => execution) if execution?
          return {:terms => terms_params}
        end
        
      end
      
    end
  end
end
