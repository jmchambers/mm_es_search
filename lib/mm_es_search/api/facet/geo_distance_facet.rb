module MmEsSearch
  module Api
    module Facet
      
      class GeoDistanceFacet < AbstractFacet
        
        key  :field, String
        many :ranges, :class_name => 'MmEsSearch::Api::Facet::RangeItem'
        key  :key_field, String
        key  :value_field, String
        key  :key_script, String
        key  :value_script, String
        key  :params, Hash
        
        key :center #any of the valid formats, see http://www.elasticsearch.org/guide/reference/query-dsl/geo-distance-filter.html
        key :unit, String, :default => "km"
        
        def to_es_query
          
          range_params = {field => center, :unit => unit}
          range_params.merge!(:ranges => ranges.map(&:attributes))
          range_params.merge!(:key_field => size)            if key_field?
          range_params.merge!(:value_field => size)          if value_field?
          range_params.merge!(:key_script => size)           if key_script?
          range_params.merge!(:value_script => size)         if value_script?
          range_params.merge!(:params => params)             unless params.empty?
          
          facet_params = {:geo_distance => range_params}.merge(super)
          
          return {label => facet_params}
          
        end
        
      end
      
    end
  end
end
