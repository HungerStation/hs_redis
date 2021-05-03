require 'hs_redis/cache_entry.rb'
module HsRedis
  class Store
    include Callbacks
    include ::HsRedis::Log::CustomLogger

    attr_accessor :name
    def initialize(name, timeout = nil)
      @name = name
      @timeout = timeout
    end

    def timeout
      @timeout || client.instance_variable_get(:@timeout) || HsRedis.configuration.timeout
    end

    def set_timeout(timeout)
      @timeout = timeout
    end

    # Fetch / store data from / to redis [GET]
    # should constructed as block
    # @param key [String]
    # @param expires_in [Integer]
    # @return [Object] data retrieved from redis
    def get(key, callback, expires_in: HsRedis.configuration.expires_in, write: true)
      begin
        result = read_get(key)
        if block_given? && (result.nil? || (result == ''))
          value = yield value
          write(key, expires_in, CacheEntry.serialize(value)) if write
          result = value
        elsif !result.nil?
          result = CacheEntry.parse(result)
        end
        result
      rescue Redis::TimeoutError, Redis::CannotConnectError, Timeout::Error, Redis::ConnectionError, Redis::CommandError => e
        logit.error(title: 'hs-redis-error' ,transaction: 'GET', error_details: e.message, stack_trace: e, timeout_setting: timeout, key: key)
        run_callback(callback)
      end
    end

    # Fetch / store multiple data from / to redis [MGET]
    # should constructed as block
    # @param keys [List<String>]
    # @param expires_in [Integer]
    # @return [Hash] Hash data retrieved from redis
    def multi_get(*keys, callback, expires_in: HsRedis.configuration.expires_in)
      begin
        return {} if keys == []
        results = read_mget(*keys)
        need_writes = {}

        fetched = keys.inject({}) do |fetch, key|
          fetch[key] = if block_given?
                         results.fetch(key) do
                           value = CacheEntry.serialize(yield key)
                           need_writes[key] = value
                           value
                         end
                       else
                         results[key]
                       end
          fetch[key] = CacheEntry.parse(fetch[key])
          fetch
        end

        # writes non existing data in redis to redis
        if block_given?
          need_writes.each do |key, value|
            write(key, expires_in, value)
          end
        end
        fetched
      rescue Redis::TimeoutError, Redis::CannotConnectError, Timeout::Error, Redis::ConnectionError, Redis::CommandError => e
        logit.error(title: 'hs-redis-error', transaction: 'MGET', error_details: e.message, stack_trace: e, timeout_setting: timeout )
        run_callback(callback)
      end
    end

    # Set redis record using SET
    # @param key [String]
    # @param value [Object]
    # @param expires_in [Integer]
    def set(key, value, callback, expires_in: HsRedis.configuration.expires_in)
      begin
        write(key, expires_in, value)
      rescue Redis::TimeoutError, Redis::CannotConnectError, Timeout::Error, Redis::ConnectionError, Redis::CommandError => e
        logit.error(transaction: 'SET', error_details: e.message, stack_trace: e, timeout_setting: timeout, key: key )
        run_callback(callback)
      end
    end

    # Set multiple redis records using MSET
    # @param hash [Hash] hash containing key-value pair
    def mapped_mset(hash, callback)
      begin
        with_timeout do
          client.with { |redis| redis.mapped_mset(hash) }
        end
      rescue Redis::TimeoutError, Redis::CannotConnectError, Timeout::Error, Redis::ConnectionError, Redis::CommandError => e
        logit.error(transaction: 'MSET', error_details: e.message, stack_trace: e, timeout_setting: timeout, key: hash.keys.join(', ') )
        run_callback(callback)
      end
    end

    # delete redis record
    # @param key [String]
    def delete(key, callback)
      begin
        delete_key(key)
      rescue Redis::TimeoutError, Redis::CannotConnectError, Timeout::Error, Redis::ConnectionError, Redis::CommandError => e
        logit.error(title: 'hs-redis-error', transaction: 'DELETE', error_details: e.message, stack_trace: e, timeout_setting: timeout, key: key )
        run_callback(callback)
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
      values = with_timeout do
                 client.with { |redis| redis.mget *keys }
               end
      Hash[keys.zip(values)].reject{|_k,v| v.nil?}
    end

    def write(key, expires_in, value)
      with_timeout do
        client.with { |redis| redis.setex(key, expires_in, value) }
      end
    end

    def read_get(key)
      with_timeout do
        client.with { |redis| redis.get(key) }
      end
    end

    def delete_key(key)
      with_timeout do
        client.with { |redis| redis.del(key) }
      end
    end

    def run_callback(callback)
      return if callback.nil?
      raise HsRedis::Errors::ProcCallback, 'Callback should be Proc' unless callback.is_a? Proc
      callback.call
    end

    ## set the time from redis client directly
    def with_timeout(&block)
      block.call
    end
  end
end
