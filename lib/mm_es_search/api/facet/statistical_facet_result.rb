module MmEsSearch
  module Api
    module Facet
      
      class StatisticalFacetResult
        
        include MongoMapper::EmbeddedDocument
        plugin MmUsesNoId
        
        key  :count, Integer
        key  :total
        key  :sum_of_squares
        key  :mean
        key  :min
        key  :max
        key  :variance
        key  :std_deviation
        
        def attributes(*args)
          attr = super
          attr.each_with_object({}) do |(key, value), hsh|
            hsh[key] = case value
            when ActiveSupport::TimeWithZone
              value.utc.to_time
            else
              value
            end
          end
        end
        alias :to_mongo :attributes
        
      end
      
    end
  end
end
