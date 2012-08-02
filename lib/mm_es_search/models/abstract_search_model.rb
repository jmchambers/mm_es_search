module AbstractSearchModel

  extend  ActiveSupport::Concern

  included do

    plugin  MmUsesUuid
    plugin  Search
      
    key  :query_string,     String
    one  :query_object,     :class_name => 'AbstractQueryModel'
    one  :sort_object,      :class_name => 'AbstractSortModel'
    one  :highlight_object, :class_name => 'MmEsSearch::API::Highlight::ResultHighlight'
    many :facets,           :class_name => 'AbstractFacetModel'
    key  :result_ids,       Array
    key  :result_total,     Integer
    key  :highlights,       Array

  end

  module ClassMethods

  end

  def run(target, options = {})
    
    page = options[:page] || options['page'] || 1
    per_page = options[:per_page] || options['per_page'] || 10
    fields = options[:fields] || []

    case target
    when :es
      
      raw_es_response = options.has_key?(:raw_es_response) ? options[:raw_es_response] : false
      sorted = options.has_key?(:sorted) ? options[:sorted] : true
      highlight = options.has_key?(:highlight) ? options[:highlight] : true
      
      if options[:facet_query] and not raw_es_response
        facets_in_display_state = facets.select {|facet| facet.current_state == :ready_for_display}
        facets_in_display_state.each(&:prepare_for_new_data)
      end

      facet_es_query = case options[:facet_query]
      when AbstractFacet
        options[:facet_query].to_es_query
      when Hash
        options[:facet_query]
      when :auto
        unless type_facet_positively_set?
          options[:facet_query] = :manual
          facets.delete_if(&:unused?)
          unless type_facet_initialized?
            facets << build_facet_model(
              :virtual_field => type_field,
              :data_type => "string",
              :exclude => type_field_excludes
            )
          end
          build_next_facet_es_query(:explore_manual_facets)
        else
          build_next_facet_es_query(:explore_manual_and_auto_facets)
        end
      when :force_auto
        build_next_facet_es_query(:explore_manual_and_auto_facets)
      when :manual
        facets_without_data_type = facets.select {|facet| facet.current_state == :need_data_type}
        add_known_data_types(facets_without_data_type)
        build_next_facet_es_query
      else
        nil
      end
      
      request = es_request(sorted, facet_es_query, highlight)
      @search_log.info(request.to_json) if debug_on?
      response = target_collection.search_hits(
        request,
        :page => page,
        :per_page => per_page,
        :ids_only => true
      )
      
      return response if raw_es_response

      @result_ids   = response.hits
      @result_total = response.total_entries
      @highlights   = response.response['hits']['hits'].map {|hit| hit['highlight']} if highlight_object? 
      out = find_hits_in_mongo(@result_ids, fields, page, per_page)

      if options[:facet_query]
        
        write_facet_results_to_models(response.facets)
        update_used_facet_missing_counts_to_zero
        update_show_missing_facet_missing_counts_to_total
        prune_facets
        facets_without_data_type = facets.select {|facet| facet.current_state == :need_data_type}
        add_known_data_types(facets_without_data_type)
        
        sanity_count = 0
        until facets.all? {|facet| facet.current_state == :ready_for_display}
          #puts cur_facets_states = self.facets.map {|f| "#{StringUtils.label_from_URI(f.virtual_field)} => #{f.current_state}"}
          facet_query = build_next_facet_es_query
          facet_results = run_for_facets_only(facet_query)
          write_facet_results_to_models(facet_results)
          prune_facets
          
          sanity_count += 1
          raise 'until loop has looped too many times!' if sanity_count > 5
        end
      end
      
      build_sort_options if respond_to? :build_sort_options
      return out  #output result set

    when :mongo
      
      request = mongo_request
      @search_log.info(request.to_json) if debug_on?
      query = target_collection.where(request)
      if sort_object.is_a?(RootSortModel)
        query = query.sort(sort_object.to_mongo_query)
      end
      if not fields.empty?
        query = query.fields(*fields)
      end
      
      response = query.paginate(:page => page, :per_page => per_page)
      @result_ids = response.map(&:_id)
      @result_total = response.total_entries
      
      return response
      
    end
  end
  
  def build_next_facet_es_query(mode = nil)
    facet_array = facets.map(&:next_facet_query)
    case mode
    when :explore_manual_facets
      facet_array << manual_facet_coverage_query
    when :explore_auto_facets
      facet_array << auto_facet_exploratory_query
    when :explore_manual_and_auto_facets
      facet_array << manual_facet_coverage_query << auto_facet_exploratory_query
    end
    facet_array_to_es_query(facet_array.compact)
  end
  
  def facet_array_to_es_query(query_array)
    es_query = {}
    query_array.each do |q|
      es_query.merge!(q.to_es_query)
    end
    
    return es_query.empty? ? nil : es_query
  end
  
  def write_facet_results_to_models(facet_results)
    unless facet_results.nil? or facet_results.empty?
      facet_results.each do |label,result|
        
        case label
        when 'auto_facet_coverage'
          
          result['terms'].each do |params|
            facets << proto_facet.new(
              :virtual_field => params['term'],
              :missing => @result_total - params['count']
            )
          end
          
        when 'manual_facet_coverage'
          
          result['terms'].each do |params|
            if current_facet = facets.detect {|f| f.virtual_field == params['term']}
              current_facet.missing = @result_total - params['count'] if current_facet
            end
          end
          
        when /^data_type_counts_for_/
          
          true_label = label[21..-1]
          data_type_counts = result['terms']
          if current_facet = facets.detect {|f| f.label == true_label}
            replace_proto_facet_with_typed_facet(current_facet.virtual_field, data_type_counts)
          end
          
        else
        
          if current_facet = facets.detect {|f| f.label == label}
            case result['_type']
            when "terms", "range"
              current_facet.build_facet_rows(result)
            when "statistical"
              current_facet.build_field_stats(result)
            end
          end
        
        end
        
      end
    end
  end
  
  def replace_proto_facet_with_typed_facet(virtual_field, data_type_param)
    if indx = facets.find_index {|f| f.virtual_field == virtual_field}
      
      current_proto_facet = facets[indx]
      
      case data_type_param
      when String
        current_proto_facet.data_type = data_type_param
      when Array
        current_proto_facet.build_data_type_counts(data_type_param)
      end
      
      raise 'proto_facet not ready for initialization' if current_proto_facet.current_state != :ready_for_initialization
      
      new_params   = current_proto_facet.attributes.except('_type').symbolize_keys
      new_facet    = build_facet_model(new_params)
      facets[indx] = new_facet
      
    end
  end
  
  def es_request(sorted = true, facet_query = nil, highlight = true)
    parse_query_string_if_needed
    query = sorted ? sorted_query : unsorted_query
    request = {
      :query => query.to_es_query,
      :query_dsl => false
    }
    if sort_object.is_a?(RootSortModel) and sorted
      request.merge!({:sort => sort_object.to_es_query})
    end
    if facet_query
      request.merge!({:facets => facet_query})
    end
    if highlight_object? and highlight
      request.merge!({:highlight => highlight_object.to_es_query})
    end
    return request
  end
  
  def mongo_request
    parse_query_string_if_needed
    sorted_query.to_mongo_query
  end
  
  def update_used_facet_missing_counts_to_zero
    #by definition, if it's been applied, all results must have it
    used_facets.each {|facet| facet.missing = 0}
  end
  
  def update_show_missing_facet_missing_counts_to_total
    used_facets.each {|facet| facet.missing = @result_total if facet.show_missing}
  end
  
  def type_facet_initialized?
    facets.any? {|facet| facet.virtual_field == type_field}
  end
  
  def type_facet_positively_set?
    used_facets.any? do |facet|
      if facet.virtual_field == type_field
        facet.rows.any? { |row| ["and", "or"].include?(row.checked) }
      else
        false
      end
    end
  end
  
  def parse_query_string_if_needed
    if query_string? and query_object.nil?
      build_query_object
    end
  end
  
  def find_hits_in_mongo(hits = @result_ids, fields = [], page = 1, per_page = @result_ids.length)
    #fetch records from db in one call and then reorder to match search result ordering
    return paginate_records([], page, per_page, @result_total) if hits.empty?
    
    ranked_ids = case hits.first
    when ElasticSearch::Api::Hit
      hits.map(&:_id)
    else
      #presume we have ids
      hits
    end 
    
    #NOTE: I use #find_with_fields to avoid redefining the standard MM #find method
    # this can be trivially implemented with the plucky #where and #fields methods
    # but is directly implemented in MmUsesUuid
    unordered_records = target_collection.find_with_fields ranked_ids, :fields => fields
    
    if unordered_records.is_a?(Array)
      records = unordered_records.reorder_by(ranked_ids.map(&:to_s), &Proc.new {|r| r.id.to_s})
    elsif unordered_records.nil?
      records = []
    else
      records = [unordered_records]
    end
    
    return paginate_records(records, page, per_page, @result_total)
    
  end
  
  def paginate_records(records, page, per_page, total)
    results = WillPaginate::Collection.new(page, per_page, total)
    results.replace(records)
    results
  end
  
  def count(target, options = {})
    parse_query_string_if_needed
    case target
    when :es
      target_collection.search_hits(unsorted_query.to_es_query, :per_page => 0).total_entries
    when :mongo
      target_collection.where(unsorted_query.to_mongo_query).count
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
    parse_query_string_if_needed
    unscored_queries, filters = sort_query_and_facets_as_filters #NOTE: we put non-RootSortModel sorts in as filters as these typically restrict results
    query = combine_queries([], unscored_queries)
    build_filtered_query(query, filters)
  end
  
  def sorted_query
    parse_query_string_if_needed
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
    query_as_filter = query_object? ? query_object.to_filter : nil
    if query_as_filter
      filters << query_as_filter
    elsif query_object?
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
  
  def build_facet_model(params)
    case params[:data_type]
    when /^string/, 'boolean', 'uri'
      build_term_facet_model(params)
    when 'integer', 'float', 'time', 'date'
      build_range_facet_model(params)
    else
      raise "unable to build a facet model for data_type = #{params[:data_type]}"
    end
  end
  
  def run_for_facets_only(facet_es_query)
    facet_result = run(:es,
      :facet_query => facet_es_query,
      :raw_es_response => true,
      :sorted => false,
      :highlight => false,
      :per_page => 0).facets
    facet_result.nil? ? {} : facet_result
  end
  
  def used_facets
    facets.select(&:used?)
  end
  
  def offered_facets
    facets.select(&:unused?)
  end
  
  
  def prune_facets
    
    prunable_facets = offered_facets.select { |f| not non_prunable_fields.include?(f[:virtual_field]) }
    fields_to_delete = {}
    
    prunable_facets.each do |facet|
      
      case facet
      when proto_facet
        
        total_present = @result_total - facet.missing
        coverage_ratio = total_present / @result_total.to_f
        
        if coverage_ratio < self.class::REQUIRED_COVERAGE_RATIO
          fields_to_delete.merge!(facet[:virtual_field] => 'coverage_ratio_too_low')
        elsif total_present < self.class::REQUIRED_COVERAGE_COUNT
          fields_to_delete.merge!(facet[:virtual_field] => 'coverage_count_too_low')
        end
        
      when AbstractTermsFacetModel
      
        #compute some stats
        largest_term_count = facet.rows.first.count
        prop_of_total = largest_term_count / @result_total.to_f
        
        if largest_term_count == 1
          fields_to_delete.merge!(facet.virtual_field => 'top_count_is_unity')
        elsif prop_of_total < 0.05
          fields_to_delete.merge!(facet.virtual_field => 'top_count_too_small')
        elsif prop_of_total > 0.75
          fields_to_delete.merge!(facet.virtual_field => 'top_count_too_big')
        end
        
      when AbstractRangeFacetModel
          
        # anything we can catch here?
      
      end
      
    end
    
    prune_and_record_reason(fields_to_delete)
    
  end
  
  def prune_and_record_reason(fields_to_delete)
    fields_to_delete.each do |virtual_field, reason|
      facets.delete_if {|facet| facet[:virtual_field] == virtual_field}
      record_prune_reason(virtual_field, reason)
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
