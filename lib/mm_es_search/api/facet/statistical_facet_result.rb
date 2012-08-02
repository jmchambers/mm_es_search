module MmEsSearch
  module Api
    module Facet
      
      class StatisticalFacetResult
        
        include MongoMapper::EmbeddedDocument
        plugin MmUsesNoId
        
        key  :count, Integer
        key  :total, Integer
        key  :sum_of_squares, Float
        key  :mean, Float
        key  :min, Float
        key  :max, Float
        key  :variance, Float
        key  :std_deviation, Float
        
      end
      
    end
  end
end
