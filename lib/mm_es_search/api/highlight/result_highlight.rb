module MmEsSearch
  module Api
    module Highlight

      class ResultHighlight
        
        include MongoMapper::EmbeddedDocument
        plugin MmUsesNoId
        
        many :fields, :class_name => 'MmEsSearch::Api::Highlight::ResultHighlight'
        key :field, String
        key :tag_schema, String
        key :pre_tags, Array
        key :post_tags, Array
        key :fragment_size, Integer
        key :number_of_fragments, Integer
        key :order, String
        
        def to_mongo_query

          raise "to_mongo_query not implemented for ResultHighlight"

        end
        
        def to_es_query

          highlight_params = self.attributes.except("fields", "pre_tags", "post_tags")
          highlight_params.merge!(:fields => fields.map(&:to_es_query)) unless fields.empty?
          highlight_params.merge!(:pre_tags => pre_tags) unless pre_tags.empty?
          highlight_params.merge!(:post_tags => post_tags) unless post_tags.empty?
          
          return field? ? {field => highlight_params.except('field')} : highlight_params

        end
        
      end
      
    end
  end
end
