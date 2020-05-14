# HsRedis

Redis client using redi-rb and Connection pool
Support multiple redis connection

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hs_redis', git: 'https://github.com/HungerStation/hs_redis.git'
```

And then execute:

    $ bundle update --source hs_redis

Or install it yourself as:

    $ gem install hs_redis

## Usage
### configuration
put this configuration in initializer
```
client = ConnectionPool.new(size: 15, timeout: 5) do
  redis = Redis.new(url: "#{Rails.application.secrets.redis_listing_url}")
  if Rails.application.secrets.redis_set_client_name
    client_name = 'listing_client'
    redis.call([:client, :setname, client_name])
  end
  redis
end

HsRedis.configure do |config|
    config.pool_size = 5
    config.timeout = 1
    config.expires_in = 60000
    config.clients = {
      listing_client: client
    }
end
```

or using :
```
HsRedis.configure do |config|
    config.pool_size = 5
    config.timeout = 1
    config.expires_in = 60000
end
HsRedis.registry.register_client(:listing_client, client)
or
HsRedis.registry.register(:listing_client, pool_size: 5, timeout: 5, redis_uri: 'redis/redis_uri', db: 0)
```
### get operation
```
callback = Proc.new { "callback_operation" }
HsRedis.client(:name).get(key, callback, expires_in: 5000) do
    //some operation
end
```

### multi get operation
```
callback = Proc.new { "callback_operation" }
HsRedis.client(:name).multi_get(*keys, callback, expires_in: 5000) do
    //some operation
end
```

### delete operation
```
callback = Proc.new { "callback_operation" }
HsRedis.client(:name).delete(key, callback)
```

### Notes
- currently, callback only for handling `Redis::TimeoutError` and `Redis::CannotConnectError`

## Development

### setup
this only for unix machine (mac OS or GNU/Linux)
run `./bin/setup`

### Coverage
- for coverage using simplecov, with minimum coverage 100 %, report will generated during running test

### running test
```rspec spec```
will produce test result with coverage statistic


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hungerstation/hs_redis.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
