require "mm_es_search/version"

module MmEsSearch
  module API
    module Query
      autoload :AbstractQuery,            "mm_es_search/api/query/abstract_query"
      autoload :AndFilter,                "mm_es_search/api/query/and_filter"
      autoload :BoolFilter,               "mm_es_search/api/query/bool_filter"
      autoload :BoolQuery,                "mm_es_search/api/query/bool_query"
      autoload :ConstantScoreQuery,       "mm_es_search/api/query/constant_score_query"
      autoload :CustomScoreQuery,         "mm_es_search/api/query/custom_score_query"
      autoload :DismaxQuery,              "mm_es_search/api/query/dismax_query"
      autoload :FilteredQuery,            "mm_es_search/api/query/filtered_query"
      autoload :HasChildFilter,           "mm_es_search/api/query/has_child_filter"
      autoload :HasChildQuery,            "mm_es_search/api/query/has_child_query"
      autoload :MatchAllQuery,            "mm_es_search/api/query/match_all_query"
      autoload :NestedFilter,             "mm_es_search/api/query/nested_filter"
      autoload :NestedQuery,              "mm_es_search/api/query/nested_query"
      autoload :NotFilter,                "mm_es_search/api/query/not_filter"
      autoload :OrFilter,                 "mm_es_search/api/query/or_filter"
      autoload :PrefixFilter,             "mm_es_search/api/query/prefix_filter"
      autoload :PrefixQuery,              "mm_es_search/api/query/prefix_query"
      autoload :QueryStringQuery,         "mm_es_search/api/query/query_string_query"
      autoload :RangeFilter,              "mm_es_search/api/query/range_filter"
      autoload :RangeQuery,               "mm_es_search/api/query/range_query"
      autoload :SingleBoolFilter,         "mm_es_search/api/query/single_bool_filter"
      autoload :TermFilter,               "mm_es_search/api/query/term_filter"
      autoload :TermQuery,                "mm_es_search/api/query/term_query"
      autoload :TermsFilter,              "mm_es_search/api/query/terms_filter"
      autoload :TermsQuery,               "mm_es_search/api/query/terms_query"
      autoload :TextQuery,                "mm_es_search/api/query/text_query"
      autoload :TopChildrenQuery,         "mm_es_search/api/query/top_children_query"
    end
    
    module Facet
      autoload :AbstractFacet,            "mm_es_search/api/facet/abstract_facet"
      autoload :DateHistogramFacet,       "mm_es_search/api/facet/date_histogram_facet"
      autoload :FilterFacet,              "mm_es_search/api/facet/filter_facet"
      autoload :GeoDistanceFacet,         "mm_es_search/api/facet/geo_distance_facet"
      autoload :HistogramFacet,           "mm_es_search/api/facet/histogram_facet"
      autoload :QueryFacet,               "mm_es_search/api/facet/query_facet"
      autoload :RangeFacet,               "mm_es_search/api/facet/range_facet"
      autoload :RangeFacetRow,            "mm_es_search/api/facet/range_facet_row"
      autoload :RangeItem,                "mm_es_search/api/facet/range_item"
      autoload :StatisticalFacet,         "mm_es_search/api/facet/statistical_facet"
      autoload :StatisticalFacetResult,   "mm_es_search/api/facet/statistical_facet_result"
      autoload :TermsFacet,               "mm_es_search/api/facet/terms_facet"
      autoload :TermsFacetRow,            "mm_es_search/api/facet/terms_facet_row"
      autoload :TermsStatsFacet,          "mm_es_search/api/facet/terms_stats_facet"
      
    end
    
    module Sort
      autoload :RootSort,                 "mm_es_search/api/sort/root_sort"
    end
    
    module Highlight
      autoload :ResultHighlight,          "mm_es_search/api/highlight/result_highlight"
    end  
  end #end API
  
  module Models
    autoload :AbstractFacetModel,       "mm_es_search/models/abstract_facet_model"
    autoload :AbstractQueryModel,       "mm_es_search/models/abstract_query_model"
    autoload :AbstractRangeFacetModel,  "mm_es_search/models/abstract_range_facet_model"
    autoload :AbstractSearchModel,      "mm_es_search/models/abstract_search_model"
    autoload :AbstractSortModel,        "mm_es_search/models/abstract_sort_model"
    autoload :AbstractTermsFacetModel,  "mm_es_search/models/abstract_terms_facet_model"
    autoload :RootSortModel,            "mm_es_search/models/root_sort_model"
    autoload :VirtualFieldSort,         "mm_es_search/models/virtual_field_sort"
  end
  
  module Utils
    autoload :SearchLogger,             "mm_es_search/utils/search_logger"
  end

end
