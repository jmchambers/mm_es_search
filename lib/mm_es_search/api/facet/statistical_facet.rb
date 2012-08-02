module MmEsSearch
  module API
    module Facet
      
      class StatisticalFacet < AbstractFacet
        
        key :field #Array or String
        key :script, String
        key :params, Hash
        
        def to_es_query
          
          stat_params = if script
            script_params = {:script => script}
            script_params.merge!({:params => params}) if params?
            script_params
          elsif field.is_a?(Array)
            {:fields => field}
          else
            {:field => field}
          end
          
          facet_params = {:statistical => stat_params}.merge(super)
          
          return {label => facet_params}
          
        end
        
      end
      
    end
  end
end
