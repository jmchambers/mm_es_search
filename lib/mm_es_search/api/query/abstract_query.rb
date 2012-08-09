module MmEsSearch
  module Api
    module Query
      
      class AbstractQuery
        
        include MongoMapper::EmbeddedDocument
        plugin  MmUsesNoId
        
        def to_filter
          QueryFilter.new(query: self)
        end
        
        def es_abs_field
          if path?
            mod_path, indx = path_and_index
            return [mod_path, field].join('.')
          else
            return field
          end
          #TODO make sure we don't need to prefix path anymore - looks like we do if same name used at diff nesting levels, so always include to be safe
        end
        
        def mongo_abs_field
          mod_path, array_index = path_and_index
          return array_index.nil? ? field : [path, field].join('.')
        end
        
        def path_and_index
          
          case path
          when /(?<=\.)[0-9]+$/
            mod_path = path.gsub(/\.[0-9]+/,'')
            array_index = path.split('.').last.to_i
          else
            mod_path = path
            array_index = nil
          end
          
          return mod_path, array_index
          
        end
        
      end
      
    end
  end
end
