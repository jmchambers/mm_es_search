module MmEsSearch
  module Models

    module AbstractSearchModel
    
      extend  ActiveSupport::Concern
      include MmEsSearch::Api::Query
      include MmEsSearch::Api::Sort
      include MmEsSearch::Api::Facet
      include MmEsSearch::Api::Highlight
      include MmEsSearch::Models
      include MmEsSearch::Utils
    
      included do
    
        NUM_TOP_RESULTS     ||= 50
        RESULT_REUSE_PERIOD ||= 30.seconds

        #one  :query_object,     :class_name => 'MmEsSearch::Models::AbstractQueryModel'
        #one  :sort_object,      :class_name => 'MmEsSearch::Models::AbstractSortModel'
        #one  :highlight_object, :class_name => 'MmEsSearch::Api::Highlight::ResultHighlight'
        #many :facets,           :class_name => 'MmEsSearch::Models::AbstractFacetModel'
        
        # key  :result_total,     Integer
        # key  :result_ids,   Array
        # key  :highlights,       Array
        key :facet_status, Symbol
        key :debug,        Boolean
        
        attr_accessor :results, :response #:query_string
    
      end
    
      module ClassMethods
    
      end
    
      def run(options = {})
        
        process_run_options(options)
        
        if can_reuse_results?
          
          puts "INFO: reusing previous results"
          extract_page_results_from_top_results
          page_results
          
        else
          
          @results = nil
          
          if @facet_mode == :auto
            remove_optional_facets
            @auto_explore_needed = true
# #NOTE hack for debugging
# @auto_explore_needed = false
            build_type_facet unless type_facet.present?
          end
          
          facets.each(&:prepare_for_new_data)
          
          if @facet_mode
            self.facet_status = :in_progress
          else
            self.facet_status = :none_requested
          end
          
          execute_query :main
          process_query_results
          route_facet_query_results
          
          if have_pending_facets?
            self.facet_status = :pending
          elsif all_facets_finished?
            self.facet_status = :complete
          end
          
# #NOTE HACK while investigating search
# self.facet_status = :complete

          save if @autosave
          
          case @return
          when :raw_response
            @response
          when :ids
            page_result_ids
          when :results
            page_results
            @results #here as a reminder that this collection is memoized
          end
          
        end
        
      end
      
      def run_facets
        
        puts "STARTED RUNNING FACETS"
        
        time = Benchmark.measure do
          
          sanity_check = 0
          while have_pending_facets? and sanity_check < 10
            #binding.pry
            facet_parent_queries.each do |parent_query|
              execute_query parent_query, :for_facets_only 
              route_facet_query_results
            end
            sanity_check += 1
          end
          
          self.facet_status = :complete
          
          #NOTE: this can throw a stack overflow if using Fibres to call run_facets async
          #this appears to be due to the limited 4k stack of a Fibre
          #and the fact that saving calls a gazillion methods
          #for this reason I use the "defer" method in Celluloid
          #as this gives async without using fibres... or something...
          #... well it works, whatever it does...
          save if @autosave
          
        end
        
        puts "ENDED RUNNING FACETS #{time.inspect}"
        
      end
      
      
      def process_run_options(options = {})
        #set instance variables for important options e.g. page, per_page
        validate_options(options)
        options = options.symbolize_keys.reverse_merge(default_run_options)
        options.each do |key, value|
          instance_variable_set "@#{key}", value
        end
      end
      
      def validate_options(options)
        valid_options  = default_run_options.keys.to_set
        valid_options += valid_options.map(&:to_s)
        unless valid_options.superset?(options.keys.to_set)
          raise "invalid options passed"
        end
        true
      end
      
      def default_run_options
        @default_run_options ||= {
          :target           => :es,
          :force_refresh    => false,
          :page             => 1,
          :per_page         => 10,
          :fields           => [],
          :return           => :results,
          :sorted           => true,
          :highlight        => true,
          :facet_mode       => :auto,
          :autosave         => false
        }
      end
      
      def page
        @page ||= 1
      end
      
      def per_page
        @per_page ||= 10
      end
      
      def have_previous_results?
        top_result_ids.present?
      end
      
      def previous_results_fresh?
        return false unless have_previous_results? and last_run_at.present?
        (Time.now - last_run_at) < RESULT_REUSE_PERIOD
      end
      
      def requested_page_in_top_results_range?
        page_range.last <= NUM_TOP_RESULTS
      end
      
      def page_range
        lower_index = (page - 1) * per_page
        upper_index = lower_index + per_page
        range       = lower_index...upper_index
      end
      
      def new_results_requested?
        @force_refresh || @raw_es_response
      end
      
      def can_reuse_results?
        !new_results_requested? && previous_results_fresh? && requested_page_in_top_results_range?
      end
      
      def extract_page_results_from_top_results
        self.page_result_ids = top_result_ids[page_range]
      end
      
      def page_results
        
        #fetch records from db in one call and then reorder to match search result ordering
        return paginate_records([]) unless page_result_ids.present?
        return @results if @results.present?
        
        #NOTE: I use #find_with_fields to avoid redefining the standard MM #find method
        # this can be trivially implemented with the plucky #where and #fields methods
        # but is directly implemented in MmUsesUuid
        unordered_records = target_collection.find_with_fields page_result_ids, :fields => @fields
        
        if unordered_records.is_a?(Array)
          records = unordered_records.reorder_by(page_result_ids.map(&:to_s), &Proc.new {|r| r.id.to_s})
        elsif unordered_records.nil?
          records = []
        else
          records = [unordered_records]
        end
        
        paginate_records(records)
        
      end
      
      def paginate_records(records)
        @results = WillPaginate::Collection.new(page, per_page, result_total || 0)
        @results.replace(records)
        @results
      end
      
      def prepare_facet_queries_for_query(query_name)
        @facet_es_queries = {}
        (facets << self).each do |facet| #NOTE we add self, as search object manages exploratory facet queries
          queries = facet.es_facet_queries_for_query(query_name)
          @facet_es_queries.merge!(queries) if queries.present?
        end
        @facet_es_queries
      end
      
      def process_facet_results(results, target_object = nil)
        results.each do |label, result|
          (target_object || self).send "handle_#{label}", result
        end
      end
      
      def execute_query(query_name, for_facets_only = false)
                
        case @target
        when :es
          
          prepare_facet_queries_for_query query_name unless @facet_mode == :none
          
          if for_facets_only
            page     = 1
            per_page = 0
            request  = es_request query_name, :sorted => false, :highlight => false
          elsif requested_page_in_top_results_range?
            page     = 1
            per_page = NUM_TOP_RESULTS
            request  = es_request query_name
          else
            page     = self.page
            per_page = self.per_page
            request  = es_request query_name
          end
          
          @search_log.info(request.except(:query_dsl).to_json) if debug_on?

          @response = target_collection.search_hits(
            request,
            :page     => page,
            :per_page => per_page,
            :ids_only => true,
            :type     => es_type_for_query(query_name)
          )
          
          @response
          
        when :mongo
          
          
          
        end
      end
      
      def build_main_query_if_missing
        self.query_object ||= build_main_query_object
      end
      
      def es_request(query_name, options = {})
        
        request = {}
        
        if query_name == :main
          
          build_main_query_if_missing
          query = @sorted ? sorted_query : unsorted_query
          request.merge!(:sort => sort_object.to_es_query)            if @sorted and sort_object.is_a?(RootSortModel)
          request.merge!(:highlight => highlight_object.to_es_query)  if @highlight and highlight_object.present?
          
        else
          
          filters = [send("build_#{query_name}_query_object").to_filter]
          query   = build_filtered_query(MatchAllQuery.new, filters)

        end
        
        request.merge!(:query  => query.to_es_query, :query_dsl => false)
        request.merge!(:facets => @facet_es_queries) if @facet_es_queries.present?
        request

      end
      
      def process_query_results
        
        case @response.hits.first
        when ElasticSearch::Api::Hit
          ids = @response.hits.map(&:_id)
        else
          ids = @response.hits
        end 

        if requested_page_in_top_results_range?
          self.top_result_ids  = ids
          extract_page_results_from_top_results
        else
          self.top_result_ids  = []
          self.page_result_ids = ids
        end
        
        self.result_total = @response.total_entries
        self.highlights   = @response.response['hits']['hits'].map {|hit| hit['highlight']} if highlight_object.present?
        
        self.last_run_at  = Time.now.utc
        
      end
      
      def route_facet_query_results
        
        facet_results = @response.facets
        return unless facet_results.present?
        
        grouped_queries = Hash.new { |hash, id| hash[id] = {} }
        facet_results.each_with_object(grouped_queries) do |(label, result), hsh|
          label_parts     = label.split('_')
          id_prefix       = label_parts.shift.to_i
          trimmed_label   = label_parts.join('_')
          hsh[id_prefix].merge!(trimmed_label => result)
        end
        
        grouped_queries.each do |obj_id, results|
          query_owner = ObjectSpace._id2ref(obj_id)
          query_owner.process_facet_results results
        end

        
      end
      
      def have_pending_facets?
        facets.any? { |f| f.current_state != :ready_for_display } || (@auto_explore_needed and type_facet_positively_set?)
      end
      
      def all_facets_finished?
        facets.all? { |f| f.current_state == :ready_for_display }
      end
      
      def prefix_label(label)
        AbstractFacetModel.prefix_label(self, label)
      end
      
      def type_facet
        facets.detect {|facet| facet.virtual_field == type_field}
      end
      
      def type_facet_positively_set?
        return false unless type_facet.present?
        type_facet.positively_checked_rows.present?
      end
      
      def used_facets
        facets.select(&:used?)
      end
      
      def unused_facets
        facets.select(&:unused?)
      end
      
      def required_facets
        facets.select(&:required?)
      end
      
      def used_or_required_facets
        facets.select(&:used_or_required?)
      end
      
      def remove_optional_facets
        facets.each do |f|
          remove_facet f unless f.used? or f.required?
        end
      end
      
      def combine_queries(scored, unscored)
        query = if scored.empty? and unscored.empty?
          MatchAllQuery.new
        elsif scored.empty?
          ConstantScoreQuery.new(
            :boost => 1,
            :query => BoolQuery.new(
              :musts => unscored
            )
          )
        elsif unscored.empty?
          if scored.length > 1
            BoolQuery.new(
              :musts => scored
            )
          else
            scored.first
          end
        else
          # mod_scored = scored.map {|query| q = query.dup; q.boost = 1e100; q }
          mod_unscored = unscored.map {|query| q = query.dup; q.boost = 0; q }
          BoolQuery.new(
            :musts => scored + mod_unscored
          )
        end
      end
      
      def unsorted_query
        build_main_query_if_missing
        unscored_queries, filters = sort_query_and_facets_as_filters #NOTE: we put non-RootSortModel sorts in as filters as these typically restrict results
        query = combine_queries([], unscored_queries)
        build_filtered_query(query, filters)
      end
      
      def sorted_query
        build_main_query_if_missing
        if (sort_object.nil? and query_object.nil?) or sort_object.is_a?(RootSortModel)
          unsorted_query
        else
          if sort_object.nil?
            query = query_object.to_query
            filters = facets_as_filters
          else
            unscored_queries, filters = query_and_facets_as_filters
            query = combine_queries([sort_object.to_query], unscored_queries)
          end
          build_filtered_query(query, filters)
        end
      end
      
      def sort_query_and_facets_as_filters
        unscored_queries, filters = query_and_facets_as_filters
        filters << sort_object.to_filter unless (sort_object.nil? or sort_object.is_a?(RootSortModel))
        return unscored_queries, filters
      end
      
      def query_and_facets_as_filters
        filters = facets_as_filters
        unscored_queries = []
        query_as_filter = query_object.present? ? query_object.to_filter : nil
        if query_as_filter
          filters << query_as_filter
        elsif query_object.present?
          unscored_queries << query_object.to_query
        end
        return unscored_queries, filters
      end
      
      def facets_as_filters
        used_facets.map(&:to_filter).compact.flatten
      end
      
      def build_filtered_query(query, filters)
        if filters.nil? or filters.empty?
          query
        else
          FilteredQuery.new(
          :query => query,
          :filter => AndFilter.new(
            :filters => filters
            )
          )
        end
      end
      
      def debug_on?
        on = !!debug
        prepare_log if on and @search_log.nil?
        on
      end
      
      def debug_on
        self.debug = true
        prepare_log unless @search_log
        return self
      end
      
      def prepare_log
        logfile = File.open(Rails.root.to_s + '/log/search.log', 'a')
        logfile.sync = true
        @search_log = SearchLogger.new(logfile)
        #@search_log.info "#{self.class.name} now logging\n"
      end
      
      def debug_off
        self.debug  = nil
        @search_log = nil
        return self
      end
      
      def target_collection
        #we assume name is of form klass.name + "Search"
        klass_match = self.class.name.match(/(?<klass>\w*)(?=Search)/)
        raise "expected the class name '#{self.class.name}' to be of form 'SomethingSearch' so that we can extract 'Something' as the target collection" unless klass_match[:klass]
        klass_match[:klass].constantize
      end
    
    end
  end
end
