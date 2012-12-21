module MmEsSearch
  module Models

    class AbstractFacetModel
      
      include MmEsSearch::Api::Facet
      include MmEsSearch::Api::Query
      include MongoMapper::EmbeddedDocument
      #plugin  MmUsesNoId
      
      key :required, Boolean
      
      def self.prefix_label(object, label)
        "#{object.object_id}_#{label}"
      end

      def prefix_label(label)
        self.class.prefix_label(self, label)
      end
      
    end
  end
end
