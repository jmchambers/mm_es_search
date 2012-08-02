module MmEsSearch
  module API
    module Query
      
      class RangeQuery < AbstractQuery
        
        key :field, String
        key :path, String
        
        key :from
        key :to
        key :include_lower, :default => true
        key :include_upper, :default => true
        key :boost, Float
        
        def to_mongo_query(options = {})
          
          range_params = {}
          
          if from
            cmd = include_lower ? '$gte' : '$gt'
            range_params.merge!({cmd => from})
          end
          
          if to
            cmd = include_upper ? '$lte' : '$lt'
            range_params.merge!({cmd => to})
          end
          
          if options[:negated]
            return {mongo_abs_field => {"$not" => range_params}}
          else
            return {mongo_abs_field => range_params}
          end
          
        end
        
        def to_es_query
          
          raise "must have either :from or :to" if from.nil? and to.nil?
          
          range_params = {}
          range_params.merge!({:from => from}) unless from.nil?
          range_params.merge!({:to => to}) unless to.nil?
          range_params.merge!({:include_lower => include_lower}) unless (from.nil? or include_lower == true)
          range_params.merge!({:include_upper => include_upper}) unless (to.nil? or include_upper == true)
          range_params.merge!({:boost => boost}) unless boost.nil?
      
          return {:range => {es_abs_field => range_params}}
          
        end
        
      end
      
    end
  end
end
