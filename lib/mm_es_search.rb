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
    
    if @dev_mode
      load File.join(root, path)
    else
      const = File.basename(path, '.rb').classify.to_sym
      autoload const, path
    end
    
  end
  
  smart_load "/mm_es_search/api/query/abstract_query.rb"
  smart_load "/mm_es_search/api/query/bool_query.rb"
  smart_load "/mm_es_search/api/query/constant_score_query.rb"
  smart_load "/mm_es_search/api/query/custom_score_query.rb"
  smart_load "/mm_es_search/api/query/dismax_query.rb"
  smart_load "/mm_es_search/api/query/filtered_query.rb"
  smart_load "/mm_es_search/api/query/has_child_query.rb"
  smart_load "/mm_es_search/api/query/match_all_query.rb"
  smart_load "/mm_es_search/api/query/nested_query.rb"
  smart_load "/mm_es_search/api/query/prefix_query.rb"
  smart_load "/mm_es_search/api/query/query_string_query.rb"
  smart_load "/mm_es_search/api/query/range_query.rb"
  smart_load "/mm_es_search/api/query/term_query.rb"
  smart_load "/mm_es_search/api/query/terms_query.rb"
  smart_load "/mm_es_search/api/query/text_query.rb"
  smart_load "/mm_es_search/api/query/top_children_query.rb"
  
  smart_load "/mm_es_search/api/query/single_bool_filter.rb"
  smart_load "/mm_es_search/utils/search_logger.rb"
    
  smart_load "/mm_es_search/api/query/and_filter.rb"
  smart_load "/mm_es_search/api/query/bool_filter.rb"
  smart_load "/mm_es_search/api/query/has_child_filter.rb"
  smart_load "/mm_es_search/api/query/nested_filter.rb"
  smart_load "/mm_es_search/api/query/not_filter.rb"
  smart_load "/mm_es_search/api/query/or_filter.rb"
  smart_load "/mm_es_search/api/query/prefix_filter.rb"
  smart_load "/mm_es_search/api/query/range_filter.rb"
  smart_load "/mm_es_search/api/query/term_filter.rb"
  smart_load "/mm_es_search/api/query/terms_filter.rb"
  smart_load "/mm_es_search/api/facet/abstract_facet.rb"
  smart_load "/mm_es_search/api/facet/date_histogram_facet.rb"
  smart_load "/mm_es_search/api/facet/filter_facet.rb"
  smart_load "/mm_es_search/api/facet/geo_distance_facet.rb"
  smart_load "/mm_es_search/api/facet/histogram_facet.rb"
  smart_load "/mm_es_search/api/facet/query_facet.rb"
  smart_load "/mm_es_search/api/facet/range_facet.rb"
  smart_load "/mm_es_search/api/facet/range_facet_row.rb"
  smart_load "/mm_es_search/api/facet/range_item.rb"
  smart_load "/mm_es_search/api/facet/statistical_facet.rb"
  smart_load "/mm_es_search/api/facet/statistical_facet_result.rb"
  smart_load "/mm_es_search/api/facet/terms_facet.rb"
  smart_load "/mm_es_search/api/facet/terms_facet_row.rb"
  smart_load "/mm_es_search/api/facet/terms_stats_facet.rb"
  smart_load "/mm_es_search/api/sort/root_sort.rb"
  smart_load "/mm_es_search/api/highlight/result_highlight.rb"
  smart_load "/mm_es_search/models/abstract_facet_model.rb"
  smart_load "/mm_es_search/models/abstract_query_model.rb"
  smart_load "/mm_es_search/models/abstract_range_facet_model.rb"
  smart_load "/mm_es_search/models/abstract_search_model.rb"
  smart_load "/mm_es_search/models/abstract_sort_model.rb"
  smart_load "/mm_es_search/models/abstract_terms_facet_model.rb"
  smart_load "/mm_es_search/models/root_sort_model.rb"
  smart_load "/mm_es_search/models/virtual_field_sort.rb"
  
  def self.directories
    [
      "mm_es_search/api/query",
      "mm_es_search/api/facet",
      "mm_es_search/api/sort",
      "mm_es_search/api/highlight",
      "mm_es_search/models",
      "mm_es_search/utils"
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


  # module API
    # module Query
      # autoload :AbstractQuery,            "mm_es_search/api/query/abstract_query"
#       
      # puts "I'm AUTOLOADING MmEsSearch"
#       
      # autoload :AndFilter,                "mm_es_search/api/query/and_filter"
      # autoload :BoolFilter,               "mm_es_search/api/query/bool_filter"
      # autoload :BoolQuery,                "mm_es_search/api/query/bool_query"
      # autoload :ConstantScoreQuery,       "mm_es_search/api/query/constant_score_query"
      # autoload :CustomScoreQuery,         "mm_es_search/api/query/custom_score_query"
      # autoload :DismaxQuery,              "mm_es_search/api/query/dismax_query"
      # autoload :FilteredQuery,            "mm_es_search/api/query/filtered_query"
      # autoload :HasChildFilter,           "mm_es_search/api/query/has_child_filter"
      # autoload :HasChildQuery,            "mm_es_search/api/query/has_child_query"
      # autoload :MatchAllQuery,            "mm_es_search/api/query/match_all_query"
      # autoload :NestedFilter,             "mm_es_search/api/query/nested_filter"
      # autoload :NestedQuery,              "mm_es_search/api/query/nested_query"
      # autoload :NotFilter,                "mm_es_search/api/query/not_filter"
      # autoload :OrFilter,                 "mm_es_search/api/query/or_filter"
      # autoload :PrefixFilter,             "mm_es_search/api/query/prefix_filter"
      # autoload :PrefixQuery,              "mm_es_search/api/query/prefix_query"
      # autoload :QueryStringQuery,         "mm_es_search/api/query/query_string_query"
      # autoload :RangeFilter,              "mm_es_search/api/query/range_filter"
      # autoload :RangeQuery,               "mm_es_search/api/query/range_query"
      # autoload :SingleBoolFilter,         "mm_es_search/api/query/single_bool_filter"
      # autoload :TermFilter,               "mm_es_search/api/query/term_filter"
      # autoload :TermQuery,                "mm_es_search/api/query/term_query"
      # autoload :TermsFilter,              "mm_es_search/api/query/terms_filter"
      # autoload :TermsQuery,               "mm_es_search/api/query/terms_query"
      # autoload :TextQuery,                "mm_es_search/api/query/text_query"
      # autoload :TopChildrenQuery,         "mm_es_search/api/query/top_children_query"
    # end
#     
    # module Facet
      # autoload :AbstractFacet,            "mm_es_search/api/facet/abstract_facet"
      # autoload :DateHistogramFacet,       "mm_es_search/api/facet/date_histogram_facet"
      # autoload :FilterFacet,              "mm_es_search/api/facet/filter_facet"
      # autoload :GeoDistanceFacet,         "mm_es_search/api/facet/geo_distance_facet"
      # autoload :HistogramFacet,           "mm_es_search/api/facet/histogram_facet"
      # autoload :QueryFacet,               "mm_es_search/api/facet/query_facet"
      # autoload :RangeFacet,               "mm_es_search/api/facet/range_facet"
      # autoload :RangeFacetRow,            "mm_es_search/api/facet/range_facet_row"
      # autoload :RangeItem,                "mm_es_search/api/facet/range_item"
      # autoload :StatisticalFacet,         "mm_es_search/api/facet/statistical_facet"
      # autoload :StatisticalFacetResult,   "mm_es_search/api/facet/statistical_facet_result"
      # autoload :TermsFacet,               "mm_es_search/api/facet/terms_facet"
      # autoload :TermsFacetRow,            "mm_es_search/api/facet/terms_facet_row"
      # autoload :TermsStatsFacet,          "mm_es_search/api/facet/terms_stats_facet"
#       
    # end
#     
    # module Sort
      # autoload :RootSort,                 "mm_es_search/api/sort/root_sort"
    # end
#     
    # module Highlight
      # autoload :ResultHighlight,          "mm_es_search/api/highlight/result_highlight"
    # end  
  # end #end API
#   
  # module Models
    # autoload :AbstractFacetModel,       "mm_es_search/models/abstract_facet_model"
    # autoload :AbstractQueryModel,       "mm_es_search/models/abstract_query_model"
    # autoload :AbstractRangeFacetModel,  "mm_es_search/models/abstract_range_facet_model"
    # autoload :AbstractSearchModel,      "mm_es_search/models/abstract_search_model"
    # autoload :AbstractSortModel,        "mm_es_search/models/abstract_sort_model"
    # autoload :AbstractTermsFacetModel,  "mm_es_search/models/abstract_terms_facet_model"
    # autoload :RootSortModel,            "mm_es_search/models/root_sort_model"
    # autoload :VirtualFieldSort,         "mm_es_search/models/virtual_field_sort"
  # end
#   
  # module Utils
    # autoload :SearchLogger,             "mm_es_search/utils/search_logger"
  # end
    
