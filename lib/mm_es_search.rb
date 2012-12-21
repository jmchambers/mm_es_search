require_relative "mm_es_search/version"
require 'active_support/core_ext'

module MmEsSearch

  def self.root
    @root ||= File.expand_path(File.dirname(__FILE__))
  end
  
  def self.smart_load(path)
    
    unless @load_mode_detected
      if @dev_mode = defined?(Rails) and Rails.env == "development"
        ActiveSupport::Dependencies.autoload_paths << root
        ActiveSupport::Dependencies.explicitly_unloadable_constants << 'MmEsSearch'
      end
      @load_mode_detected = true
    end
    
    full_path = File.join(root, "#{path}.rb")
    
    if @dev_mode
      load full_path
    else
      require full_path
    end
    
  end
  
  smart_load "mm_es_search/utils/search_logger"
  smart_load "mm_es_search/utils/facet_row_utils"
  
  smart_load "mm_es_search/api/query/abstract_query"
  smart_load "mm_es_search/api/query/bool_query"
  smart_load "mm_es_search/api/query/constant_score_query"
  smart_load "mm_es_search/api/query/custom_filters_score_query"
  smart_load "mm_es_search/api/query/custom_score_query"
  smart_load "mm_es_search/api/query/dismax_query"
  smart_load "mm_es_search/api/query/filtered_query"
  smart_load "mm_es_search/api/query/has_child_query"
  smart_load "mm_es_search/api/query/has_parent_query"
  smart_load "mm_es_search/api/query/match_all_query"
  smart_load "mm_es_search/api/query/nested_query"
  smart_load "mm_es_search/api/query/prefix_query"
  smart_load "mm_es_search/api/query/query_string_query"
  smart_load "mm_es_search/api/query/range_query"
  smart_load "mm_es_search/api/query/term_query"
  smart_load "mm_es_search/api/query/terms_query"
  smart_load "mm_es_search/api/query/text_query"
  smart_load "mm_es_search/api/query/top_children_query"
  
  smart_load "mm_es_search/api/query/abstract_filter"
  smart_load "mm_es_search/api/query/single_bool_filter"
  
  smart_load "mm_es_search/api/query/and_filter"
  smart_load "mm_es_search/api/query/bool_filter"
  smart_load "mm_es_search/api/query/has_child_filter"
  smart_load "mm_es_search/api/query/has_parent_filter"
  smart_load "mm_es_search/api/query/match_all_filter"
  smart_load "mm_es_search/api/query/nested_filter"
  smart_load "mm_es_search/api/query/not_filter"
  smart_load "mm_es_search/api/query/or_filter"
  smart_load "mm_es_search/api/query/prefix_filter"
  smart_load "mm_es_search/api/query/query_filter"
  smart_load "mm_es_search/api/query/range_filter"
  smart_load "mm_es_search/api/query/scored_filter"
  smart_load "mm_es_search/api/query/term_filter"
  smart_load "mm_es_search/api/query/terms_filter"
  
  smart_load "mm_es_search/api/facet/terms_facet_row"
  smart_load "mm_es_search/api/facet/abstract_facet"
  smart_load "mm_es_search/api/facet/date_histogram_facet"
  smart_load "mm_es_search/api/facet/filter_facet"
  smart_load "mm_es_search/api/facet/geo_distance_facet"
  smart_load "mm_es_search/api/facet/histogram_facet"
  smart_load "mm_es_search/api/facet/query_facet"
  smart_load "mm_es_search/api/facet/range_facet"
  smart_load "mm_es_search/api/facet/range_facet_row"
  smart_load "mm_es_search/api/facet/range_item"
  smart_load "mm_es_search/api/facet/statistical_facet"
  smart_load "mm_es_search/api/facet/statistical_facet_result"
  smart_load "mm_es_search/api/facet/terms_facet"
  smart_load "mm_es_search/api/facet/terms_stats_facet"
  
  smart_load "mm_es_search/api/sort/root_sort"
  
  smart_load "mm_es_search/api/highlight/result_highlight"
  
  smart_load "mm_es_search/models/abstract_facet_model"
  smart_load "mm_es_search/models/abstract_query_model"
  smart_load "mm_es_search/models/abstract_range_facet_model"
  smart_load "mm_es_search/models/abstract_search_model"
  smart_load "mm_es_search/models/abstract_sort_model"
  smart_load "mm_es_search/models/abstract_terms_facet_model"
  smart_load "mm_es_search/models/root_sort_model"
  smart_load "mm_es_search/models/virtual_field_sort"
  
  def self.directories
    [
      "mm_es_search/utils",
      "mm_es_search/api/query",
      "mm_es_search/api/facet",
      "mm_es_search/api/sort",
      "mm_es_search/api/highlight",
      "mm_es_search/models"
    ]
  end
  
  def self.each_file

    directories.each do |dir, array|
      dir_constants = dir.split('/').map(&:classify)
      Dir[File.join(root, dir, "**/*.rb")].sort.each do |fname|
        basename = File.basename(fname, '.rb')
        constant = basename.classify.to_sym
        qualified_constant = (dir_constants + [constant]).join('::')
        path     = fname.chomp File.extname(fname)
        yield qualified_constant, constant, fname, path, basename
      end
    end
    
  end

end