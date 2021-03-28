module HsRedis
  module Clients
    class Registry
      class << self
        # register connection pool
        # @param name [String], connection name
        # @param connection_pool [Object], object of ConnectionPool
        def register_client(name, connection_pool)
          validate_registration(name)
          registered_clients[name.to_sym] = connection_pool
        end

        # register redis connection pool
        # @param name [String], connection name
        # @param pool_size [Integer], connection pool size, default is 5
        # @param timeout [Integer], connection timeout, default is 5
        # @param client_name [String], redis client name , optional
        # @param redis_url [String], http formatted string for redis uri
        # @param db [Integer], redis DB, default 0
        def register(name, pool_size: HsRedis.configuration.pool_size, timeout: HsRedis.configuration.timeout, client_name: nil, redis_uri: nil, db: 0)
          raise HsRedis::Errors::MissingParameter, "Missing Redis URI, url:#{redis_uri}" unless redis_uri
          redis_client_instance = register_redis(name, redis_uri, db, client_name)
          redis_pool = ConnectionPool.new(size: pool_size, timeout: timeout) { redis_client_instance }
          validate_registration(name)
          registered_clients[name.to_sym] = redis_pool
        end

        def unregister(name)
          registered_clients.delete name.to_sym if registered? name.to_sym
        end

        def registered_clients
          @registered_clients ||= Hash.new
        end

        def registered?(name)
          registered_clients.keys.include? name.to_sym
        end

        def registered_stores
          @registered_stores ||= Hash.new
        end

        def store_registered?(name)
          registered_stores.keys.include? name.to_sym
        end

        private

        def register_redis(name, redis_uri, db, client_name)
          begin
            redis = Redis.new(url: "#{redis_uri}/#{db}")
            client_name = client_name || name.upcase
            redis.call([:client, :setname, client_name])
            redis
          rescue Redis::TimeoutError
            raise HsRedis::Errors::Timeout, 'Connection Timeout'
          end
        end

        def validate_registration(name)
          raise HsRedis::Errors::AlreadyRegistered, 'Client Already Registered, please choose differet name' if registered? name
        end
      end
    end
  end
end