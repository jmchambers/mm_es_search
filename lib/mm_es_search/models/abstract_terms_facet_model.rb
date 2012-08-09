module MmEsSearch
  module Models
    
    module AbstractTermsFacetModel
      extend ActiveSupport::Concern
      
      included do
        
        DEFAULT_NUM_RESULTS ||= 10
        
        # redefinition to include default
        many :rows, :class_name => 'MmEsSearch::Api::Facet::TermsFacetRow'
        key  :exclude, Array
        key  :other, Integer
        
        aasm_initial_state -> facet {facet.valid? ? :need_row_data : :missing_required_fields}
        
        aasm_event :typed_facet_initialized do
          transitions :to => :need_row_data, :from  => [:ready_for_initialization]
        end
        
        aasm_event :prepare_for_new_data, :after => :prune_unchecked_rows do
          transitions :to => :need_row_data, :from => [:ready_for_display]
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
        
        def result_name
          'terms'
        end
        
        def row_class
          TermsFacetRow
        end
        
        def build_facet_rows(result)
          self.other = result['other']
          super(result)
        end
        
        def to_facet
          TermsFacet.new(
            default_params.merge(
              :label   => prefix_label('display_results'),
              :size    => (@num_result_rows || self.class::DEFAULT_NUM_RESULTS) + checked_rows.length,
              :exclude => exclude
            )
          )
        end
        
        def required_row_fields
          ['term']
        end
    
      end
      
    end
  end
end
