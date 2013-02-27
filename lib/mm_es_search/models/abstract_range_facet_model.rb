module MmEsSearch
  module Models
    module AbstractRangeFacetModel
      
      extend  ActiveSupport::Concern
      include MmEsSearch::Api::Facet
      include MmEsSearch::Api::Query
    
      included do
        
        TARGET_NUM_ROLES ||= 5
        TIME_UNITS          = [:year, :month, :day, :hour, :min, :sec].freeze
        DEFAULT_TIME_PARAMS = [1970, 1, 1, 0, 0, 0].freeze
        
        many :rows,  :class_name => 'MmEsSearch::Api::Facet::RangeFacetRow'
        one  :stats, :class_name => 'MmEsSearch::Api::Facet::StatisticalFacetResult'
        key  :display_mode, String

        aasm_initial_state -> facet do
          if facet.valid?
            if facet.rows.present?
              :ready_for_display
            else
              :need_field_stats
            end
          else
            :missing_required_fields
          end
        end
        
        aasm_event :typed_facet_initialized do
          transitions :to => :need_field_stats, :from  => [:ready_for_initialization]
        end
        
        aasm_event :field_stats_set do
          transitions :to => :need_row_data, :from => [:need_field_stats, :need_row_data]
        end
        
        aasm_event :prepare_for_new_data, :after => :prune_unchecked_rows do
          transitions :to => :need_field_stats, :from => [:ready_for_display, :need_field_stats, :need_row_data]
        end
        
      end
    
      module ClassMethods
        
        def new(params = {})
          new_instance = super(params)
          new_instance.typed_facet_initialized
          new_instance
        end
    
      end
      
      def result_name
        'ranges'
      end
      
      def is_time?
        false
      end
      
      def timezone_matters?
        true
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
        StatisticalFacet.new(
          default_params.merge(
            :label        => prefix_label('field_stats_result'),
            :facet_filter => facet_filter
          )
        )
      end
  
      # def facet_filter
        # #override this to provide additional constraints
        # nil
      # end
  
      def to_facet
        case display_mode || select_display_mode
        when "range"
          initialize_rows
          RangeFacet.new(
            default_params.merge(
              :label        => prefix_label('display_result'),
              :ranges       => rows.map(&:to_range_item),
              :facet_filter => facet_filter
            )
          )
        when "histogram"
          raise NotImplementedError
        else
          raise "display mode '#{display_mode}' is not recognised"
        end
      end
      
      #NOTE: we use this pair of methods to transform between es and client-side units
      # and the @transform_lookup ensures we avoid value creep through rounding errors
      # in other words, if we ask for 100-200 in client-side units, we get that, not e.g. 101-201
      # def deserialize_value(value)
        # value
      # end
#       
      # def serialize_value(value)
        # value
      # end
      
      def initialize_rows
        @transform_lookup = {}
        if is_time?
          initialize_time_rows
        else
          initialize_numeric_rows
        end
      end
      
      def best_time_unit
        if rows.present?
          all_times = rows.map { |r| [r.from, r.to] }.flatten.compact
          min = all_times.min
          max = all_times.max
        else
          min = stats.min
          max = stats.max
        end
        diff = Time.diff(min, max)
        if    diff[:year].abs   > 0 then :year
        elsif diff[:month].abs  > 0 then :month
        elsif diff[:day].abs    > 0 then :day
        elsif diff[:hour].abs   > 0 then :hour
        elsif diff[:minute].abs > 0 then :min
        elsif diff[:second].abs > 0 then :sec
                                    else :year
        end
      end
      
      def deserialize_value(key, es_value)
        
        case key
        when "total", "sum_of_squares", "variance"
          return nil #i.e. discard these
        end
        
        if @transform_lookup and stored_val = @transform_lookup[es_value]
          return stored_val
        end
        
        if is_time?
          
          case key
          when "from", "to", "min", "max", "mean"
                        
            if timezone_matters?
              case es_value
              when Numeric
                Time.zone.at(es_value/1000)
              when String
                Time.zone.parse es_value
              end
            else
              t = case es_value
              when Numeric
                Time.at(es_value/1000)
              when String
                Time.parse es_value
              end
              Time.zone.local(*t.to_a[0..5].reverse)
            end
            
          when "std_deviation"
            es_value/1000
            
          when "count"
            es_value
            
          end
          

        else
          es_value
        end
        
      end
      
      def serialize_value(value, for_filter = false)
        es_value = if is_time?
          t = if timezone_matters?
            value.utc
          else
            Time.utc(*value.to_a[0..5].reverse)
          end
          for_filter ? t.iso8601 : t.to_f*1000
        else
          value
        end
        @transform_lookup ||= {}
        @transform_lookup[es_value] = value
        es_value
      end
      
      def handle_field_stats_result(result)
        build_field_stats transform_field_stats(result)
      end
      
      def transform_field_stats(result)
        result.each_with_object({}) do |(key, value), output|
          output[key] = deserialize_value(key, value)
        end
      end

      def get_time_stats(time_unit)
        min, max, mean = [:min, :max, :mean].map do |stat|
          stats.send(stat).send time_unit
        end
        long_time_unit = case time_unit
        when :sec then :second
        when :min then :minute
        else time_unit
        end
        sd = stats.std_deviation/(1.send long_time_unit) #e.g. 1.year or 1.month
        return min, max, mean, sd
      end

      def initialize_time_rows
        time_unit = best_time_unit
        min, max, mean, sd = get_time_stats(time_unit)
        range_vals = calculate_range_values(min, max, mean, sd)
        unit_index = TIME_UNITS.index(time_unit)
        row_times = range_vals.map do |val|
          time_params = DEFAULT_TIME_PARAMS.dup
          if unit_index > 0 #e.g. if all same year, copy year across from stats.mean
            mean_array = stats.mean.to_a[0..5].reverse
            time_params[0..unit_index-1] = mean_array[0..unit_index-1]
          end
          time_params[unit_index] = val
          Time.zone.local(*time_params)
        end
        es_times = row_times.map do |row_time|
          serialize_value(row_time).tap do |es_time|
            @transform_lookup[es_time] = row_time
          end
        end
        build_rows(es_times)
      end
      
      def calculate_range_values(min, max, mean, sd)
        
        #TODO come up with a system that works with decimal values
        # AND when the diff between lower and upper is very small or zero
        
        final_casting = if min.is_a?(Float) or max.is_a?(Float)
          :to_f
        else
          :to_i
        end
        
        # orig_range = max - min
        # if orig_range < 50 and not orig_range.zero?
          # scale = (50/orig_range.floor)
          # scale = round_to_power_of_ten(scale, :up, [(scale.to_s.length - 1), 1].max)
          # min, max, mean, sd = [min, max, mean, sd].map { |v| v*scale }
        # else
          # scale = nil
        # end
        
        orig_lower = [min.floor, (mean - sd).floor].max
        orig_upper = [max.ceil, (mean + sd).ceil].min
        orig_range = orig_upper - orig_lower
        
        if orig_range < 100 and not orig_range.zero?
          #binding.pry
          scale = (100/orig_range.floor)
          scale = round_to_power_of_ten(scale, :up, [(scale.to_s.length - 1), 1].max)
          lower, upper, range = [orig_lower, orig_upper, orig_range].map { |v| v*scale }
        else
          lower, upper, range = orig_lower, orig_upper, orig_range
          scale = nil
        end
        
        power = if range.zero?
          lower.to_s.length - 1
        else  
          range.to_s.length - 1
        end
        
        lower = round_to_power_of_ten(lower, :down, power)
        upper = round_to_power_of_ten(upper, :up, power)
        orig_inc = ((upper - lower) / (TARGET_NUM_ROLES-2)).floor
        
        #binding.pry
        
        inc = round_to_power_of_ten(orig_inc, :up, power)
        
        if inc == 0
          values = [lower - 5, lower + 5] #TODO remove this once pruning support is added
          #binding.pry
        else
          values = (TARGET_NUM_ROLES-1).times.map { |i| lower + inc*i }
          if (gte_upper = values.select { |n| n >= upper }).length > 1
            values = values[0..-gte_upper.length]
          end
        end
        
        values.map!(&final_casting)
        puts "SCALE SCALE SCALE is #{scale}"
        if scale and not scale.zero?
          values.map! { |v| v/scale }
        end
        
        #binding.pry if orig_range == 0
        puts "values are: #{values}"
        
        values
        
      end
      
      def initialize_numeric_rows
        values = calculate_range_values(stats.min, stats.max, stats.mean, stats.std_deviation)
        build_rows(values)
      end
      
      def build_rows(values)
        self.rows = checked_rows #NOTE: we preserve selected rows
        if (num_values = values.length) == 2
          rows << RangeFacetRow.new(:from => values.first, :to => values.last)
        else
          rows << RangeFacetRow.new(:to => values.first)                          # -> 1 (if starting with 1,2,3,4)
          (num_values - 1).times do
            rows << RangeFacetRow.new(:from => values.shift, :to => values.first) # 1 -> 2,  2 -> 3,  3 -> 4
          end
          rows << RangeFacetRow.new(:from => values.first) if num_values > 1      # 4 ->
        end
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
