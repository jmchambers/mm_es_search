module MmEsSearch
  module Api
    module Facet
      
      class RangeItem
        
        include MongoMapper::EmbeddedDocument
        plugin MmUsesNoId
        
        key :from
        key :to
        
      end
      
    end
  end
end
