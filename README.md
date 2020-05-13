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
HsRedis.client(:name).get(key, expires_in: 5000, callback) do
    //some operation
end
```

### multi get operation
```
callback = Proc.new { "callback_operation" }
HsRedis.client(:name).multi_get(*keys, expires_in: 5000, callback) do
    //some operation
end
```

### delete operation
```
callback = Proc.new { "callback_operation" }
HsRedis.client(:name).delete(key, callback)
```

### Notes
currently, callback only for handling `Redis::TimeoutError`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hungerstation/hs_redis.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
