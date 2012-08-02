module MmEsSearch
  module Utils
    class SearchLogger < Logger
      def format_message(severity, timestamp, progname, msg)
        "#{timestamp.to_formatted_s(:db)} #{severity}\n#{msg}\n" 
      end 
    end
  end
end

