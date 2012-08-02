module MmEsSearch
  module Models

    class AbstractFacetModel
      
      include MmEsSearch::Api::Facet
      include MmEsSearch::Api::Query
      include MongoMapper::EmbeddedDocument
      #plugin MmUsesNoId
      
      key :show_missing, Boolean
      key :rows, Array
      
      def label
        self._id.to_s
      end
      
      def used?
        checked_rows.any? || show_missing
      end
      
      def unused?
        !used?
      end
      
      def find_row_by_params(params)
        rows.detect do |row|
          required_row_fields.all? {|field| row[field] == params[field]}
        end
      end
      
      def checked_rows
        return [] if rows.empty?
        rows.select {|row| row.checked?}
      end
      
      def positively_checked_rows
        return [] if rows.empty?
        rows.select {|row| ["and", "or"].include?(row.checked)}
      end
      
      def rows_checked_and
        return [] if rows.empty?
        rows.select {|row| row.checked == 'and'}
      end
      
      def unchecked_rows
        return [] if rows.empty?
        rows.select {|row| row.checked? == false}
      end
      
      def to_filter
        
        if show_missing
          build_filter
        else
          used_rows = checked_rows
          return nil if used_rows.empty?
          
          and_array  = get_checked_row_params('and')
          or_array   = get_checked_row_params('or')
          not_array  = get_checked_row_params('not')
          build_filter(and_array, or_array, not_array)
        end
    
      end
      
      def get_checked_row_params(check_mark)
        checked_rows.select {|row| row.checked == check_mark} .map {|row| row.attributes.only(*required_row_fields)}
      end
      
    end
  end
end
