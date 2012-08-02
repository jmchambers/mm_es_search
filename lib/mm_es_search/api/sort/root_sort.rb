module MmEsSearch
  module Api
    module Sort

      class RootSort
        
        include MongoMapper::EmbeddedDocument
        plugin MmUsesNoId
        
        #only support one sort field as have no need for multi as yet...
        key :field
        key :direction
        
        def to_mongo_query
          case direction
          when "asc", "ascending", nil
            {field => :asc}
          when "desc", "descending"
            {field => :desc}
          end
        end
        
        def to_es_query
          case direction
          when "asc", "ascending", nil
            {field => {:order => :asc}}
          when "desc", "descending"
            {field => {:order => :desc}}
          end
        end
        
      end
      
    end
  end
end
