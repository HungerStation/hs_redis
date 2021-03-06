module HsRedis
  class Configuration
    def initialize
      @configuration = OpenStruct.new
      @configuration.custom_errors = [
        Redis::ConnectionError,
        Redis::CommandError
      ]
    end

    def timeout
      @configuration.timeout
    end

    def timeout=(timeout)
      @configuration.timeout = timeout
    end

    def pool_size
      @configuration.pool_size
    end

    def pool_size=(pool_size)
      @configuration.pool_size = pool_size
    end

    def expires_in
      @configuration.expires_in
    end

    def expires_in=(expires_in)
      @configuration.expires_in = expires_in
    end

    def clients
      HsRedis::Clients::Registry.registered_clients
    end

    def clients=(clients)
      clients.each do |key, value|
        HsRedis::Clients::Registry.register_client(key, value)
      end
    end

    def api_version
      @configuration.api_version
    end

    def api_version=(api_version)
      @configuration.api_version = api_version
    end

    def registry
      HsRedis::Clients::Registry
    end

    def registry=(registry)
      @configuration.registry = registry
    end

    def custom_errors
      @configuration.custom_errors
    end

    def custom_errors=(errors)
      @configuration.custom_errors = errors
    end
  end

  def self.configuration
    @configuration ||= initialize_configuration!
  end

  def self.configure
    yield(configuration)
  end

  def self.registry
    self.configuration.registry
  end

  def self.client(name)
    unless HsRedis::Clients::Registry.store_registered?(name)
      HsRedis::Clients::Registry.registered_stores[name.to_sym] = HsRedis::Store.new(name)
    end

    HsRedis::Clients::Registry.registered_stores[name.to_sym]
  end

  def self.initialize_configuration!
    @configuration = Configuration.new
    @configuration.timeout = 5
    @configuration.api_version = 1
    @configuration.pool_size = 5
    @configuration.expires_in = 60000
    @configuration.registry = HsRedis::Clients::Registry
    @configuration
  end
end
