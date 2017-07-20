require 'logger'
require 'json'

module KPM
  class LoggerDecorator < Logger

    attr_accessor :silent

    # The initialize method
    # Params:
    # +logdev+:: The log device.  This is a filename (String) or IO object.
    # +shift_age+:: Number of old log files to keep, *or* frequency of rotation .
    # +shift_size+:: Maximum logfile size (only applies when +shift_age+ is a number).
    # +silent+:: Suppress parent class outputs
    def initialize(logdev, shift_age = 0, shift_size = 1048576, silent=false)
      @container = Hash.new
      @silent = silent
      super logdev, shift_age, shift_size
    end

    # This is an override of the debug method.
    # Params
    # +message+:: The message to log
    # +key+:: If passed, it will indicate that the message is a child (array or object) identified by the key
    #         within a group (array) in the container (Hash)
    # +group+:: If passed it will indicate that the message must be part of a group (array) in a Hash
    def debug(progname, group=nil, key=nil, &block)
      add_to_hash(DEBUG, progname, group, key)
      super(progname, &block) unless silent
    end

    # This is an override of the info method.
    # Params
    # +message+:: The message to log
    # +key+:: If passed, it will indicate that the message is a child (array or object) identified by the key
    #         within a group (array) in the container (Hash)
    # +group+:: If passed it will indicate that the message must be part of a group (array) in a Hash
    def info(progname, group=nil, key=nil, &block)
      add_to_hash(INFO, progname, group, key)
      super(progname, &block) unless silent
    end

    # This is an override of the warn method.
    # Params
    # +message+:: The message to log
    # +key+:: If passed, it will indicate that the message is a child (array or object) identified by the key
    #         within a group (array) in the container (Hash)
    # +group+:: If passed it will indicate that the message must be part of a group (array) in a Hash
    def warn(progname, group=nil, key=nil, &block)
      add_to_hash(WARN, progname, group, key)
      super(progname, &block) unless silent
    end

    # This is an override of the error method.
    # Params
    # +message+:: The message to log
    # +key+:: If passed, it will indicate that the message is a child (array or object) identified by the key
    #         within a group (array) in the container (Hash)
    # +group+:: If passed it will indicate that the message must be part of a group (array) in a Hash
    def error(progname, group=nil, key=nil, &block)
      add_to_hash(ERROR, progname, group, key)
      super(progname, &block) unless silent
    end

    # This is an override of the fatal method.
    # Params
    # +message+:: The message to log
    # +key+:: If passed, it will indicate that the message is a child (array or object) identified by the key
    #         within a group (array) in the container (Hash)
    # +group+:: If passed it will indicate that the message must be part of a group (array) in a Hash
    def fatal(progname, group=nil, key=nil, &block)
      add_to_hash(FATAL, progname, group, key)
      super(progname, &block) unless silent
    end

    # Return JSON representation of the logs
    def to_json
      @container.to_json
    end

    # Return String representation of the logs
    def to_s
      @container.to_s
    end

    # Return HASH representation of the logs
    def to_hash
      @container
    end

    private
      # This procedures will store the logs into a hash to be later returned
      # Params
      # +severity+:: The severity to store (DEBUG, INFO, WARN, ERROR and FATAL)
      # +message+:: The message to store
      # +key+:: If passed, it will indicate that the message is a child (array or object) identified by the key
      #         within a group (array) in the container (Hash)
      # +group+:: If passed it will indicate that the message must be part of a group (array) in a Hash
      def add_to_hash(severity, message, group=nil, key=nil)

        if @logdev.nil? or severity < @level
          return true
        end
        container_key = group.nil? ? severity_to_symbol(severity) : group.to_sym

        if key.nil? && group.nil?
          @container[container_key] ||= []
          @container[container_key].push(message)
        else
          @container[container_key] ||= Hash.new
          child_key = key.nil? ? severity_to_symbol(severity) : key.to_sym

          unless @container[container_key][child_key].nil?
            child_is_an_array = @container[container_key][child_key].kind_of?(Array)

            old_message = nil
            old_message = @container[container_key][child_key] unless child_is_an_array
            @container[container_key][child_key] = [] unless child_is_an_array
            @container[container_key][child_key].push(old_message) unless old_message.nil?
            @container[container_key][child_key].push(message)
          else
            @container[container_key][child_key] = message
          end

        end
      end

      # Return a symbol representation of a severity
      # Param
      # +severity+:: The severity to symbol (DEBUG, INFO, WARN, ERROR and FATAL)
      def severity_to_symbol(severity)
        return :debug if severity == DEBUG
        return :info if severity == INFO
        return :warn if severity == WARN
        return :error if severity == ERROR
        return :fatal if severity == FATAL
      end
  end
end