module MmEsSearch
  module API
    module Facet
      
      class TermsFacet < AbstractFacet
        
        key :field #Array or String
        key :size, Integer
        key :order, String
        key :exclude, Array #of Strings
        
        key :script_field, String
        
        key :regex, String
        key :regex_flags, String
        
        key :script, String
        key :params, Hash
        
        def to_es_query
          
          term_params = {}
          term_params.merge!(:field => field)               if field.is_a?(String)
          term_params.merge!(:fields => field)              if field.is_a?(Array)
          term_params.merge!(:size => size)                 if (size? and size != 10)
          term_params.merge!(:order => order)               if (order? and order != "count")
          term_params.merge!(:exclude => exclude)           unless exclude.empty?
          term_params.merge!(:script_field => script_field) if script_field?
          term_params.merge!(:regex => regex)               if regex?
          term_params.merge!(:regex_flags => script_field)  if regex_flags?
          term_params.merge!(:script => script)             if script?
          term_params.merge!(:params => params)             unless params.empty?
          
          facet_params = {:terms => term_params}.merge(super)
          
          return {label => facet_params}
 
        end
        
        
      end
      
    end
  end
end
