module Avalon
  module Duration
    def milliseconds_to_formatted_time( milliseconds )
      total_seconds = milliseconds / 1000
      hours = total_seconds / (60 * 60)
      minutes = (total_seconds / 60) % 60
      seconds = total_seconds % 60

      output = ''
      if hours > 0
        output += "#{hours}:"
      end

      output += "#{minutes.to_s.rjust(2,'0')}:#{seconds.to_s.rjust(2,'0')}"
      output
    end
  end
end
