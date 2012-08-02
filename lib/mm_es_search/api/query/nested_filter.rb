module MmEsSearch
  module Api
    module Query
      
      class NestedFilter < NestedQuery
        
        private
        
        def es_api_keyword
          :filter
        end
        
        def anded_query(query_array)
          AndFilter.new(:filters => query_array)
        end
        
      end
      
    end
  end
end
