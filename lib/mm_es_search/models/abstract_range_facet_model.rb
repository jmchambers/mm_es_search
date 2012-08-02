module MmEsSearch
  module Models
    module AbstractRangeFacetModel
      extend ActiveSupport::Concern
    
      included do
        many :rows,  :class_name => 'MmEsSearch::Api::Facet::RangeFacetRow'
        one  :stats, :class_name => 'MmEsSearch::Api::Facet::StatisticalFacetResult'
        key  :display_mode, String
        
        aasm_initial_state -> facet {facet.valid? ? :need_field_stats : :missing_required_fields}
        
        aasm_event :typed_facet_initialized do
          transitions :to => :need_field_stats, :from  => [:ready_for_initialization]
        end
        
        aasm_event :field_stats_set do
          transitions :to => :need_row_data, :from => [:need_field_stats, :need_row_data]
        end
        
        aasm_event :prepare_for_new_data, :after => :prune_unchecked_rows do
          transitions :to => :need_field_stats, :from => [:ready_for_display]
        end
        
      end
    
      module ClassMethods
        
        def new(params)
          new_instance = super(params)
          new_instance.typed_facet_initialized
          new_instance
        end
    
      end
    
      module InstanceMethods
        
        include MmEsSearch::Api::Facet
        include MmEsSearch::Api::Query
        
        def result_name
          'ranges'
        end
        
        def row_class
          RangeFacetRow
        end
        
        def build_field_stats(result)
          self.stats = StatisticalFacetResult.new(result.except('_type'))
          zero_rows
          current_state
          field_stats_set
        end
        
        def to_stats_facet
          StatisticalFacet.new(default_params)
        end
    
        def to_facet
          case display_mode || select_display_mode
          when "range"
            initialize_rows
            RangeFacet.new( default_params.merge(:ranges => rows.map(&:to_range_item)) )
          when "histogram"
            
          else
            raise "display mode '#{display_mode}' is not recognised"
          end
        end
        
        def initialize_rows
          one_sd = stats.std_deviation
          orig_lower = [stats.min.floor, (stats.mean - one_sd).floor].max
          orig_upper = [stats.max.ceil, (stats.mean + one_sd).ceil].min
          range = orig_upper - orig_lower
          power = range.to_s.length - 1
          lower = round_to_power_of_ten(orig_lower, :down, power)
          upper = round_to_power_of_ten(orig_upper, :up, power)
          inc = ((upper - lower) / 5).floor
          r = [lower, lower + inc]
          
          self.rows = checked_rows #NOTE: we preserve selected rows
          rows << RangeFacetRow.new(:to => r.last)
          elem_sum(r, inc)
          3.times do
            rows << RangeFacetRow.new(:from => r.first, :to => r.last)
            elem_sum(r, inc)
          end
          rows << RangeFacetRow.new(:from => r.first)
        end
        
        def elem_sum(ary, inc)
          ary.map! {|x| x + inc}
        end
        
        def round_to_power_of_ten(n, direction, power)
          p = 10**power
          return n if (n % p).zero?
          case direction
          when :up
            n + (p - n % p)
          when :down
            n - n % p
          end
        end
        
        def select_display_mode
          #logic for setting mode based on stats
          #TODO build this logic
          if true
            self.display_mode = "range"
          end
        end
        
        def required_row_fields
          ['from', 'to']
        end
        
      end
      
    end
  end
end
