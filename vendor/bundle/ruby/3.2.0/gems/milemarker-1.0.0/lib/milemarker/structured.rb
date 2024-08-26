# frozen_string_literal: true

class Milemarker
  # Milemarker for structured logging
  #   * #create_logger! creates a logger that spits out JSON lines instead of human-centered strings
  #   * #batch_line and #final_line return hashes of count/time/rate data
  #     *...and are aliased to #batch_data and #final_data
  #
  # Milemarker::Structured should be a drop-in replacement for Milemarker, with the above differences
  # and of course the caveat that if you provide your own logger it should expect to deal with
  # the hashes coming from #batch_data and #final_data
  class Structured < Milemarker
    # Create a logger that spits out JSON strings instead of human-oriented strings'
    # In addition to whatever message is passed, will always also include
    # { level: severity, time: datetime }
    #
    # The logger will try to deal intelligently with different types of arguments
    #   * a Hash will just be passed
    #   * a String;s return json will show up in the hash under the key 'msg'
    #   * an Exception's return json will have the error's message, class, the first bit of the backtrace, and hostname
    #   * Anything else will be treated like a hash if it responds to #to_h;
    #     otherwise use msg.inspect as a message string
    def create_logger!(*args, **kwargs)
      super
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        case msg
        when Hash
          msg
        when String
          { msg: msg }
        when Exception
          exception_message_hash(msg)
        else
          other_message_hash(msg)
        end.merge({ level: severity, time: datetime }).to_json
      end
      self
    end

    # @return [Hash] hash with information about the last batch
    def batch_line
      {
        name: name,
        batch_count: last_batch_size,
        batch_seconds: last_batch_seconds,
        batch_rate: batch_rate,
        total_count: count,
        total_seconds: total_seconds_so_far,
        total_rate: total_rate
      }
    end

    alias batch_data batch_line

    # @return [Hash] hash with information about the last batch
    def final_line
      {
        name: name,
        final_batch_size: final_batch_size,
        total_count: count,
        total_seconds: total_seconds_so_far,
        total_rate: total_rate
      }
    end

    alias final_data final_line

    def exception_message_hash(msg)
      { msg: msg.message, error: msg.class, at: msg.backtrace&.first, hostname: Socket.gethostname }
    end

    def other_message_hash(msg)
      if msg.respond_to? :to_h
        msg.to_h
      else
        { msg: msg.inspect }
      end
    end
  end
end
