module MmEsSearch
  module Models
    
    class VirtualFieldSort < AbstractSortModel
      
      key :virtual_field, String
      key :data_type, String
      
      def to_es_query
        to_query.to_es_query
      end
      
      def to_query
        NestedQuery.new(
          :score_mode => "max",
          :path => path,
          :query => CustomScoreQuery.new(
            :script => sort_script,
            :query => TermQuery.new(
              :path => path,
              :field => field,
              :value => virtual_field
            )
          )
        )
      end
      
      def to_filter
        NestedFilter.new(
          :path => path,
          :query => TermFilter.new(
            :path => path,
            :field => field,
            :value => virtual_field
          )
        )
      end
      
      def sort_script
        sort_field = self.sort_field
        mod_path = path.gsub(/\.[0-9]+/,'')
        case direction    
        when "asc", "ascending", nil
          "0 - doc['#{mod_path}.#{sort_field}'].value"
        when "desc", "descending"
          "0 + doc['#{mod_path}.#{sort_field}'].value"
        end
      end
      
    end
  end 
end
