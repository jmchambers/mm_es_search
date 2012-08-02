module MmEsSearch
  module Api
    module Facet
      
      class RangeFacetRow
        
        include MongoMapper::EmbeddedDocument
        include ActionView::Helpers::NumberHelper
        plugin MmUsesNoId
        
        key  :from
        key  :to
        key  :count, Integer
        key  :min
        key  :max
        key  :total_count, Integer
        key  :total
        key  :mean
        
        key :checked, String
        
        def zero_count
          self.count = 0
        end
        
        def to_range_item
          RangeItem.new(:from => from, :to => to)
        end
        
        def to_english(pretty_print = true)
          case from || to
          when Numeric
            render_numeric(pretty_print)
          when Time, DateTime
          end
        end
        
        def render_numeric(pretty_print)
          
          if pretty_print
            #TODO handle units (see http://bit.ly/rhx05t)
            from_formatted = number_to_human(from) if from?
            to_formatted = number_to_human(to) if to?
          else
            from_formatted = from if from?
            to_formatted = to if to?
          end
          
          if from? and to?
            "from #{from_formatted} to #{to_formatted}"
          elsif from?
            "#{from_formatted} or greater"
          else
            "upto #{to_formatted}"
          end
          
        end
        
        def to_form_name(data_type)
          params = []
          params << "data_type:#{data_type}"
          params << "from:#{from}" if from?
          params << "to:#{to}" if to?
          return params.join('&')
        end
        
      end
      
    end
  end
end
