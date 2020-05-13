require 'spec_helper'

RSpec.describe HsRedis::Configuration do
  let(:configuration) { described_class.new }

  it 'can set timeout' do
    expected_timeout = 5
    configuration.timeout = expected_timeout
    expect(configuration.timeout).to eq(expected_timeout)
  end

  it 'can set api version' do
    expected_api_version = rand 1..10
    configuration.api_version = expected_api_version

    expect(configuration.api_version).to eq(expected_api_version)
  end

  it 'can set pool size' do
    expected_pool_size = rand 1..10
    configuration.pool_size = expected_pool_size

    expect(configuration.pool_size).to eq(expected_pool_size)
  end

  it 'can set the expires_in' do
    expected_expires_in = rand 1..100
    configuration.expires_in = expected_expires_in
    expect(configuration.expires_in).to eq expected_expires_in
  end

  it 'can set the clients' do
    client = ConnectionPool.new(size: 5, timeout: 5) { Redis.new }
    expected_client = { client1: client }
    configuration.clients = expected_client
    expect(configuration.clients).to eq expected_client
  end

  it 'can set registry' do
    expected_registry = HsRedis::Clients::Registry
    configuration.registry = expected_registry
    expect(configuration.registry).to eq expected_registry
  end

  it 'can get default registry' do
    expect(HsRedis.registry).to eq HsRedis::Clients::Registry
  end

  it 'can get client' do
    expect(HsRedis.client(:name).is_a? HsRedis::Store).to eq true
  end
end