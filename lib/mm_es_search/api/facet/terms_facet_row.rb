module MmEsSearch
  module Api
    module Facet
      
      class TermsFacetRow
        
        include MongoMapper::EmbeddedDocument
        plugin  MmUsesUuid
        
        key :term, String
        key :count, Integer
        
        key :checked, String
        
        def zero_count
          self.count = 0
        end
        
        def to_english(pretty_print = true)
          StringUtils.label_from_URI(term)
        end
        
        def to_form_name(data_type)
          term
        end
        
        def parent
          _parent_document
        end
        
      end
      
    end
  end
end
