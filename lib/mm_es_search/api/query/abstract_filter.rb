module MmEsSearch
  module Api
    module Query
      
      module AbstractFilter
        extend  ActiveSupport::Concern
        
        def to_filter
          self
        end
      end
      
    end
  end
end
