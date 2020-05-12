module HsRedis
  module Clients
    class Registry
      class << self
        # register connection pool
        # @param name [String], connection name
        # @param connection_pool [Object], object of ConnectionPool
        def register(name, connection_pool)
          raise HsRedis::Errors::AlreadyRegistered unless client_exist? name
          registered_client[name.to_sym] = connection_pool
        end

        # register redis connection pool
        # @param name [String], connection name
        # @param pool_size [Integer], connection pool size, default is 5
        # @param timeout [Integer], connection timeout, default is 5
        # @param client_name [String], redis client name , optional
        # @param redis_url [String], http formatted string for redis uri
        # @param db [Integer], redis DB, default 0
        def register(name, pool_size: HsRedis::Configuration.pool_size, timeout: HsRedis.Configuration.timeout, client_name: nil, redis_uri: nil, db: 0)
          raise HsRedis::Errors::MissingParameter 'Missing Redis URI' unless redis_uri
          redis_pool = ConnectionPool.new(size: 5, timeout: 5) do
            begin
              redis = Redis.new(url: "#{redis_uri}/#{db}")
              client_name = client_name || name.upcase
              redis.call([:client, :setname, client_name])
              redis
            rescue Redis::TimeoutError
              raise Redis::TimeoutError, 'Connection Timeout'
            end
          end
          raise HsRedis::Errors::AlreadyRegistered unless client_exist? name
          registered_client[name.to_sym] = redis_pool
        end

        def registered_client
          @registered_client ||= Hash.new
        end

        private

        def client_exist?(name)
          @registered_client.keys.include? name.to_sym
        end
      end
    end
  end
end