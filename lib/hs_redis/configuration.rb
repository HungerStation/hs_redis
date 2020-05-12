module HsRedis
  class Configuration
    def initialize
      @configuration = OpenStruct.new
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
  end

  def self.configuration
    @configuration ||= initialize_configuration!
  end

  def self.configure
    yield(configuration)
  end

  def self.initialize_configuration!
    @configuration = Configuration.new
    @configuration.timeout = 5
    @configuration.api_version = 1
    @configuration.pool_size = 5
    @configuration
  end

end