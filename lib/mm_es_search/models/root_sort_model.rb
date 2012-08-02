module MmEsSearch
  module Models
    class RootSortModel < AbstractSortModel
      
      key :field, String
      
      # def to_query
      # end
      
      def to_mongo_query
        RootSort.new(:field => field, :direction => direction).to_mongo_query
      end
      
      def to_es_query
        RootSort.new(:field => field, :direction => direction).to_es_query
      end
      
    end
  end
end
