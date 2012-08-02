module MmEsSearch
  module API
    module Facet
      
      class RangeFacet < AbstractFacet
        
        key  :field, String
        many :ranges, :class_name => 'MmEsSearch::API::Facet::RangeItem'
        key  :key_field, String
        key  :value_field, String
        key  :key_script, String
        key  :value_script, String
        key  :params, Hash
        
        def to_es_query
          
          range_params = {}
          range_params.merge!(:field => field)               if field?
          range_params.merge!(:ranges => ranges.map(&:attributes))
          range_params.merge!(:key_field => size)            if key_field?
          range_params.merge!(:value_field => size)          if value_field?
          range_params.merge!(:key_script => size)           if key_script?
          range_params.merge!(:value_script => size)         if value_script?
          range_params.merge!(:params => params)             unless params.empty?
          
          facet_params = {:range => range_params}.merge(super)
          
          return {label => facet_params}
          
        end
        
      end
      
    end
  end
end
