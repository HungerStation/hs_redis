if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
  SimpleCov.minimum_coverage(100)
end

require 'bundler/setup'
require 'hs_redis'
require 'fakeredis/rspec'

require 'pry'
require 'redis'
require 'mock_redis'
require 'connection_pool'
require 'ffaker'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    mock_redis = MockRedis.new
    allow(Redis).to receive(:new).and_return(mock_redis)
  end
end
