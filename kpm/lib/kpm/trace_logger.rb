require 'json'

module KPM
  class TraceLogger
    def initialize
      @trace = Hash.new
    end

    # Return JSON representation of the logs
    def to_json
      @trace.to_json
    end

    # Return String representation of the logs
    def to_s
      @trace.to_s
    end

    # Return HASH representation of the logs
    def to_hash
      @trace
    end

    def add(group = nil, key, message)
      add_to_hash(group, key, message);
    end

    private

    # This procedures will store the logs into a hash to be later returned
    def add_to_hash(group = nil, key, message)
      if group.nil? || key.nil?
        add_with_key(group || key, message)
      else
        container_key = group.to_sym

        @trace[container_key] ||= Hash.new
        child_key = key.to_sym

        unless @trace[container_key][child_key].nil?
          child_is_an_array = @trace[container_key][child_key].kind_of?(Array)

          old_message = nil
          old_message = @trace[container_key][child_key] unless child_is_an_array
          @trace[container_key][child_key] = [] unless child_is_an_array
          @trace[container_key][child_key].push(old_message) unless old_message.nil?
          @trace[container_key][child_key].push(message)
        else
          @trace[container_key][child_key] = message
        end
      end
    end

    def add_with_key(key, message)
      child_key = key.to_sym

      unless @trace[child_key].nil?
        child_is_an_array = @trace[child_key].kind_of?(Array)

        old_message = nil
        old_message = @trace[child_key] unless child_is_an_array
        @trace[child_key] = [] unless child_is_an_array
        @trace[child_key].push(old_message) unless old_message.nil?
        @trace[child_key].push(message)
      else
        @trace[child_key] = message
      end
    end
  end
end
