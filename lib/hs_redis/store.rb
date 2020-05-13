module HsRedis
  class Store
    def initialize(name)
      @name = name
    end

    # Fetch / store multiple data from / to redis [MGET]
    # should constructed as block
    # @param key [String]
    # @param expires_in [Integer]
    # @return [Hash] Hash data retrrieved from redis
    def multi_get(*keys, expires_in: HsRedis::Configuration.expires_in)
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
        writes(key, expires_in, value)
      end

      fetched
    end

    private

    def client
      raise HsRedis::Errors::NotRegistered unless HsRedis::Cliens::Registry.registered? name
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

    def writes(key, expires_in, value)
      client.with { |redis| redis.setex(key, expires_in, value) }
    end
  end
end