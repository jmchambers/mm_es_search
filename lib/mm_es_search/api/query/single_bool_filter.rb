module MmEsSearch
  module API
    module Query
      
      class SingleBoolFilter < AbstractQuery
        
        many :filters, :class_name => 'MmEsSearch::API::Query::AbstractQuery'
        key  :_cache, Boolean
      
        def operator_name
          self.class.to_s[0..-7].split('::').last.downcase #strip off "Filter" and downcase e.g. AndFilter => filter
        end
        
        def optimize_filters
          opt_filters = []
          filters.each do |child_filter|
            if child_filter.is_a?(self.class)
              opt_filters += child_filter.filters
            else
              opt_filters << child_filter
            end
          end
          opt_filters
        end
        
        def to_mongo_query(options = {})
          case self
          when NotFilter
            negated_options = options.merge({:negated => !options[:negated]})
            return AndFilter.new(:filters => filters).to_mongo_query(negated_options)
          else
            opt_filters = optimize_filters
            filter_array = opt_filters.map {|filter| filter.to_mongo_query(options)}
            if filter_array.length == 1
              return filter_array.first
            else
              return {"$#{operator_name}" => filter_array}
            end
          end
        end
        
        def to_es_query
          opt_filters = optimize_filters
          filter_array = opt_filters.map {|query| query.to_es_query}
          params = {}
          case self
          when NotFilter
            if filter_array.length == 1
              return {operator_name => {:filter => filter_array.first}}
            else
              return {operator_name => {:filter => {:and => filter_array}}}
            end
          else
            params = {operator_name => filter_array}
          end
          params.merge!({"_cache" => _cache}) unless _cache.nil?
          return params
        end
        
      end
      
    end
  end
end
