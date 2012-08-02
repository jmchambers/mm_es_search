module MmEsSearch
  module API
    module Facet

      class AbstractFacet
        
        include MongoMapper::EmbeddedDocument
        include MmEsSearch::API::Query
        plugin MmUsesNoId
        
        key :label, String
        key :nested, String
        one :facet_filter, :class_name => 'MmEsSearch::API::Query::AbstractQuery'
        
        def to_es_query
          facet_params = {}
          facet_params.merge!({:nested => nested}) if nested?
          facet_params.merge!({:facet_filter => facet_filter.to_es_query}) if facet_filter?
          return facet_params
        end
        
      end
      
    end
  end
end
