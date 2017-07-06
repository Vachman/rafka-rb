module Rafka
  class Producer
    include GenericCommands

    # Access the underlying Redis client object
    attr_reader :redis

    # Create a new client instance.
    #
    # @param [Hash] opts
    # @option opts [String] :host ("localhost") server hostname
    # @option opts [Fixnum] :port (6380) server port
    # @options opts [Hash] :redis_opts Configuration options for the underlying
    #   Redis client
    #
    # @return [Producer]
    def initialize(opts = {})
      opts[:redis_opts] = {} if !opts[:redis_opts]
      opts = parse_opts(opts)
      @redis = Redis.new(host: opts[:host], port: opts[:port])
    end

    # Produce a message. This is an asynchronous operation.
    #
    # @param topic [String]
    # @param msg [#to_s]
    #
    # @example
    #   produce("greetings", "Hello there!")
    def produce(topic, msg)
      Rafka.wrap_errors do
        @redis.rpushx("topics:#{topic}", msg.to_s)
      end
    end

    # Flush any buffered messages. Blocks until all messages are flushed or
    # timeout exceeds.
    #
    # @param timeout_ms [Fixnum] (5000) The timeout in milliseconds
    #
    # @return [Fixnum] The number of unflushed messages
    def flush(timeout_ms=5000)
      Rafka.wrap_errors do
        @redis.dump(timeout_ms.to_s)
      end
    end

    private

    # @return [Hash]
    def parse_opts(opts)
      DEFAULTS.dup.merge(opts).merge(opts[:redis_opts])
    end
  end
end
