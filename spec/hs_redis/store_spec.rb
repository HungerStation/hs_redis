require 'spec_helper'

RSpec.describe HsRedis::Store do
  let!(:connection_pool) do
    ConnectionPool.new(size: 5, timeout: 5) do
      redis
    end
  end

  let(:redis) { Redis.new }

  let(:callback) { Proc.new { raise HsRedis::Errors::Timeout } }

  before do
    HsRedis.configure do |config|
      config.pool_size = 5
      config.timeout = 1
      config.expires_in = 60000
      config.clients = {
        mock_client: connection_pool
      }
    end
  end

  after do
    HsRedis::Clients::Registry.unregister('mock_client')
  end

  context 'single fetch' do
    context 'given timeout' do
      it 'should raise callback with exception' do
        allow(redis).to receive(:get).and_raise(Redis::TimeoutError)
        expect do
          described_class.new(:mock_client).get('test_key', callback) { 'sample' }
        end.to raise_error(HsRedis::Errors::Timeout)
      end
    end

    context 'given valid response from redis' do
      it 'should store same data' do
        key = FFaker::Lorem::word
        value  = FFaker::Lorem.characters
        result = described_class.new(:mock_client).get(key, callback) do |on|
                   value
                 end
        expect(value).to eq redis.get key
        expect(result).to eq value
      end
    end
  end

  context 'multiple fetch' do
    context 'given timeout' do
      it 'should raise callback with exception' do
        allow(redis).to receive(:mget).and_raise(Redis::TimeoutError)
        data = {
          key1: FFaker::Lorem.characters,
          key2: FFaker::Lorem.characters
        }
        expect do
          described_class.new(:mock_client).multi_get(*data.keys, callback) { |key| data[key] }
        end.to raise_error(HsRedis::Errors::Timeout)
      end
    end

    context 'given valid response from redis' do
      it 'should store same data' do
        data = {
          key1: FFaker::Lorem.characters,
          key2: FFaker::Lorem.characters
        }
        results = described_class.new(:mock_client).multi_get(*data.keys, callback) do |key|
                   data[key]
                 end
        expect(data.values).to eq redis.mget *data.keys
        expect(results.values).to eq data.values
      end
    end
  end

  context 'delete key' do
    it 'should return success if key exists' do
      key = FFaker::Lorem::word
      value  = FFaker::Lorem.characters
      client = described_class.new(:mock_client)
      result = client.get(key, callback) do
                  value
                end
      expect(value).to eq redis.get key
      expect(client.delete(key, callback)).to eq 1
    end

    it 'should return failed if key did not exist' do
      key = FFaker::Lorem::word
      client = described_class.new(:mock_client)
      expect(client.delete(key, callback)).to eq 0
    end

    it 'should raise callback with exception when timeout' do
      allow(redis).to receive(:del).and_raise(Redis::TimeoutError)
      key = FFaker::Lorem::word
      client = described_class.new(:mock_client)
      expect do
        client.delete(key, callback)
      end.to raise_error(HsRedis::Errors::Timeout)
    end

    it 'should raise HsRedis::Errors::ProcCallback when given no Proc Callback' do
      allow(redis).to receive(:del).and_raise(Redis::TimeoutError)
      key = FFaker::Lorem::word
      local_callback = "callback".upcase
      client = described_class.new(:mock_client)
      expect do
        client.delete(key, local_callback)
      end.to raise_error(HsRedis::Errors::ProcCallback)
    end
  end
end