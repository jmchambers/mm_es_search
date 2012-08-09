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
    
        NUM_TOP_RESULTS     ||= 500
        RESULT_REUSE_PERIOD ||= 30.seconds

        #one  :query_object,     :class_name => 'MmEsSearch::Models::AbstractQueryModel'
        #one  :sort_object,      :class_name => 'MmEsSearch::Models::AbstractSortModel'
        #one  :highlight_object, :class_name => 'MmEsSearch::Api::Highlight::ResultHighlight'
        #many :facets,           :class_name => 'MmEsSearch::Models::AbstractFacetModel'
        
        # key  :result_total,     Integer
        # key  :result_ids,   Array
        # key  :highlights,       Array
        
        attr_accessor :current_query, :page_result_ids, :query_string, :results
    
      end
    
      module ClassMethods
    
      end
    
      def run(options = {})
        
        process_run_options(options)
        
        if can_reuse_results?
          
          puts "INFO: reusing previous results"
          extract_page_results_from_top_results
          find_page_results_in_mongo
          
        else
          
          if @facet_mode == :auto and not type_facet.present?
            build_type_facet
          end
            
          execute_query :main
          return @response if @raw_es_response

          process_query_results
          route_facet_query_results
          
          while have_unfinished_facets?
            facet_parent_queries.each do |parent_query|
              execute_query parent_query, :for_facets_only 
              route_facet_query_results
            end
          end
          
          @results
          
        end
        
      end
      
      def process_run_options(options = {})
        #set instance variables for important options e.g. @page, @per_page
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
          :current_query    => :main,
          :force_refresh    => :false,
          :page             => 1,
          :per_page         => 10,
          :fields           => [],
          :raw_es_response  => false,
          :sorted           => true,
          :highlight        => true,
          :facet_mode       => :auto
        }
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
        lower_index = (@page - 1) * @per_page
        upper_index = lower_index + @per_page
        range       = lower_index...upper_index
      end
      
      def can_reuse_results?
        previous_results_fresh? && requested_page_in_top_results_range?
      end
      
      def extract_page_results_from_top_results
        self.page_result_ids = top_result_ids[page_range]
      end
      
      def find_page_results_in_mongo
        
        #fetch records from db in one call and then reorder to match search result ordering
        return paginate_records([], @page, @per_page, result_total) unless page_result_ids.present?
        
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
        @results = WillPaginate::Collection.new(@page, @per_page, result_total)
        @results.replace(records)
        @results
      end
      
      def gather_facet_queries
        request_queries_from_existing_facets
        request_exploratory_facet_queries
      end
      
      def request_queries_from_existing_facets
        
      end
      
      def request_exploratory_facet_queries
        
      end
      
      def prepare_facet_queries_for_query(query_name)
        @facet_es_queries = {}
        (facets << self).each do |facet|
          queries = facet.es_facet_queries_for_query?(query_name)
          @facet_es_queries.merge!(queries) if queries.present?
        end
        @facet_es_queries
      end
      
      def es_facet_queries_for_query?(query_name)
        #TODO check whether we need to add any exploratory facet queries e.g. type facet
      end
      
      def execute_query(query_name, for_facets_only = false)
        case @target
        when :es
          
          prepare_facet_queries_for_query query_name
          
          if for_facets_only
            page     = 1
            per_page = 0
            request  = es_request query_name, :sorted => false, :highlight => false
          elsif requested_page_in_top_results_range?
            page     = 1
            per_page = NUM_TOP_RESULTS
            request  = es_request query_name
          else
            page     = @page
            per_page = @per_page
            request  = es_request query_name
          end
          
          @search_log.info(request.to_json) if debug_on?
          
          @response = target_collection.search_hits(
            request,
            :page     => page,
            :per_page => per_page,
            :ids_only => true
          )
          
        when :mongo
          
          
          
        end
      end
      
      def build_main_query_if_missing
        build_main_query_object if @query_string and query_object.nil?
      end
      
      def es_request(query_name, options = {})
        
        request = {}
        
        if query_name == :main
          
          build_main_query_if_missing
          query = @sorted ? sorted_query : unsorted_query
          request.merge!(:sort => sort_object.to_es_query)            if @sorted and sort_object.is_a?(RootSortModel)
          request.merge!(:highlight => highlight_object.to_es_query)  if @highlight and highlight_object.present?
          
        else
          
          query = send "build_#{query_name}_query_object"

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
        
        find_page_results_in_mongo
        
      end
      
      def route_facet_query_results
        
        grouped_queries = Hash.new { |hash, id| hash[id] = {} }
        @response.facets.each_with_object(grouped_queries) do |label_and_result, hsh|
          label, result   = label_and_result
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
      
      def have_unfinished_facets?
        
      end
      
      def facet_parent_queries
        (self.facet_parent_queries + facets.map(&:facet_parent_queries)).flatten.uniq
      end
      
      def facet_parent_queries
        [:main]
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
      
      def offered_facets
        facets.select(&:unused?)
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
        used_facets.map(&:to_filter).compact
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
        if defined?(@debug_on)
          @debug_on
        else
          debug_off
          false
        end
      end
      
      def debug_on
        @debug_on = true
        logfile = File.open(Rails.root.to_s + '/log/search.log', 'a')
        logfile.sync = true
        @search_log = SearchLogger.new(logfile)
        @search_log.info "#{self.class.name} now logging\n"
        return self
      end
      
      def debug_off
        @debug_on = false
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
