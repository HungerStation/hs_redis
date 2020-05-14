module HsRedis
  class Store
    include Callbacks

    attr_writer :name
    attr_reader :name
    def initialize(name)
      @name = name
    end

    def get(key, timeout_callback, expires_in: HsRedis.configuration.expires_in, &block)
      begin
        result = read_get(key)
        unless result
          value = yield value
          write(key, expires_in, value)
          result = value
        end
        result
      rescue Redis::TimeoutError, Redis::CannotConnectError => e
        run_callback(timeout_callback)
      end
    end

    # Fetch / store multiple data from / to redis [MGET]
    # should constructed as block
    # @param key [String]
    # @param expires_in [Integer]
    # @return [Hash] Hash data retrrieved from redis
    def multi_get(*keys, timeout_callback, expires_in: HsRedis.configuration.expires_in, &block)
      begin
        return {} if keys == []
        results = read_mget(*keys)
        need_writes = {}

        fetched = keys.inject({}) do |fetch, key|
          fetch[key] = results.fetch(key) do
            value = yield key
            need_writes[key] = value
            value
          end
          fetch
        end

        # writes non existing data in redis to redis
        need_writes.each do |key, value|
          write(key, expires_in, value)
        end
        fetched
      rescue Redis::TimeoutError, Redis::CannotConnectError => e
        run_callback(timeout_callback)
      end
    end

    # delete redis record
    # @param key [String]
    def delete(key, timeout_callback, &block)
      begin
        delete_key(key)
      rescue Redis::TimeoutError, Redis::CannotConnectError => e
        run_callback(timeout_callback)
      end
    end

    private

    def client
      raise HsRedis::Errors::NotRegistered, 'Client Not Registered, please register in configuration' unless HsRedis::Clients::Registry.registered? name
      @client ||= HsRedis::Clients::Registry.registered_clients[name.to_sym]
    end

    # read multiple data from redis
    # @param keys [Array], array of keys
    # @return [Hash] hash data retrieved from redis
    def read_mget(*keys)
      return {} if keys == []

      values = client.with { |redis| redis.mget *keys }
      Hash[keys.zip(values)].reject{|k,v| v.nil?}
    end

    def write(key, expires_in, value)
      client.with { |redis| redis.setex(key, expires_in, value) }
    end

    def read_get(key)
      client.with { |redis| redis.get(key) }
    end

    def delete_key(key)
      client.with { |redis| redis.del(key) }
    end

    def run_callback(callback)
      raise HsRedis::Errors::ProcCallback, 'Callback should be Proc' unless callback.is_a? Proc
      callback.call
    end
  end
end
