module MmEsSearch
  module API
    module Query
      
      class NestedQuery < AbstractQuery
      
        one :query, :class_name => 'MmEsSearch::API::Query::AbstractQuery'
        key :path, String
        key :score_mode, String
        key :_scope, String
        key :array_index_name, String
        
        def to_mongo_query(options = {})
          
          mod_path, array_index = path_and_index
          if array_index.nil?
            {path => {'$elemMatch' => query.to_mongo_query(options)}}
          else
            query.to_mongo_query(options) #don't need elemMatch as index means we're addressing one document only
          end
          
        end
        
        def to_es_query
          
          mod_path, array_index = path_and_index
          mod_query = if array_index.nil?
            query
          else
            query_array = [
              query,
              TermQuery.new(:path => mod_path, :field => array_index_name || '_array_index', :value => array_index)]
            anded_query(query_array)
          end

          nested_params = {
            es_api_keyword => mod_query.to_es_query,
            :path => mod_path
          }
          nested_params.merge!({:score_mode => score_mode}) unless score_mode.nil?
          nested_params.merge!({:_scope => _scope}) unless _scope.nil?
      
          return {:nested => nested_params}
      
        end
        
        private
        
        def es_api_keyword
          :query
        end
        
        def anded_query(query_array)
          BoolQuery.new(:musts => query_array)
        end
      
      end
      
    end
  end
end
