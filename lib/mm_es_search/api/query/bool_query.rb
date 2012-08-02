module MmEsSearch
  module Api
    module Query
      
      class BoolQuery < AbstractQuery
        
        many :musts, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        many :shoulds, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        many :must_nots, :class_name => 'MmEsSearch::Api::Query::AbstractQuery'
        key :boost, Float
        key :minimum_number_should_match, Integer
        
        def validate
          raise "cannot have a must_not by itself in a BoolQuery" if (musts.empty? and shoulds.empty? and not self.is_a?(BoolFilter))
        end
        
        def to_mongo_query(options = {})
          
          validate
          
          negated_options = options.merge({:negated => !options[:negated]})
          
          and_array = musts.map {|query| query.to_mongo_query(options)} + must_nots.map {|query| query.to_mongo_query(negated_options)}
          or_array = shoulds.map {|query| query.to_mongo_query(options)}
          
          bool_params = {}
          bool_params.merge!({'$and' => and_array}) unless and_array.empty?
          bool_params.merge!({'$or' => or_array}) unless or_array.empty?
          
          return bool_params
          
        end
        
        def to_es_query
          
          validate
          
          # use more optimal and, or, not SingleBoolFilter if appropriate
          if self.is_a?(BoolFilter)
            if (shoulds + must_nots).empty? and not musts.empty? and boost.nil?
              return AndFilter.new(:filters => musts).to_es_query
            elsif (musts + must_nots).empty? and not shoulds.empty? and boost.nil? and minimum_number_should_match == 1
              return OrFilter.new(:filters => shoulds).to_es_query
            elsif (musts + shoulds).empty? and not must_nots.empty? and boost.nil?
              return NotFilter.new(:filters => must_nots).to_es_query
            end
          end
          
          must_array = musts.map {|query| query.to_es_query}
          should_array = shoulds.map {|query| query.to_es_query}
          must_not_array = must_nots.map {|query| query.to_es_query}
          
          bool_params = {}
          bool_params.merge!({:must => must_array}) unless must_array.empty?
          bool_params.merge!({:should => should_array}) unless should_array.empty?
          bool_params.merge!({:must_not => must_not_array}) unless must_not_array.empty?
          bool_params.merge!({:boost => boost}) unless boost.nil?
          bool_params.merge!({:minimum_number_should_match => minimum_number_should_match}) if minimum_number_should_match?
          return {:bool => bool_params}
          
        end
        
      end
      
    end
  end
end
