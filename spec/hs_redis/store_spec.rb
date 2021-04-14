require 'spec_helper'
require 'hs_redis/cache_entry.rb'
RSpec.describe HsRedis::Store do
  let!(:connection_pool) do
    ConnectionPool::Wrapper.new(size: 5, timeout: 5) do
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
        result = described_class.new(:mock_client).get(key, callback) do
                   value
                end
        expect(value).to eq HsRedis::CacheEntry.parse(redis.get key)
        expect(result).to eq value
      end
    end

    context 'having old format data in redis' do
      it 'should return the old formatted data with no error' do
        key = FFaker::Lorem::word
        value  = JSON.generate({id: '123.456', data: FFaker::Lorem.characters})
        redis.setex(key, HsRedis.configuration.expires_in, value)
        result = described_class.new(:mock_client).get(key, callback)
        expect(value).to eq redis.get key
        expect(value).to eq HsRedis::CacheEntry.parse(redis.get key)
        expect(result).to eq value
      end
    end


    context 'given no fallback with data already saved' do
      it 'should store same data' do
        key = FFaker::Lorem::word
        value  = FFaker::Lorem.characters
        described_class.new(:mock_client).get(key, callback) do
          value
        end
        result = described_class.new(:mock_client).get(key, nil)
        expect(value).to eq HsRedis::CacheEntry.parse(redis.get key)
        expect(result).to eq value
      end
    end
  end

  context 'changed timeout' do
    it 'should reflect in instance timeout' do
      mock_client = described_class.new(:mock_client)
      expect(mock_client.timeout).to eq(connection_pool.instance_variable_get(:@timeout) || HsRedis.configuration.timeout)
      expected_timeout = 0.05
      mock_client.set_timeout(expected_timeout) #set timeout to 50 milliseconds
      expect(mock_client.timeout).to eq expected_timeout
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
        redis_results = redis.mget *data.keys
        expect(data.values).to eq redis_results.map{|rr| HsRedis::CacheEntry.parse(rr)}
        expect(results.values).to eq data.values
      end
    end

    context 'given no fallback to redis' do
      it 'should return no data' do
        data = {
            key1: FFaker::Lorem.characters,
            key2: FFaker::Lorem.characters
        }
        results = described_class.new(:mock_client).multi_get(*data.keys, callback)
        redis_results = redis.mget *data.keys
        expect(redis_results.map{|rr| HsRedis::CacheEntry.parse(rr)}).to eq [nil, nil]
        expect(results.values).to eq [nil, nil]
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
      expect(value).to eq HsRedis::CacheEntry.parse(redis.get key)
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

  describe '#set' do
    let(:callback) { Proc.new {} }
    let(:key) { 'test_key' }
    let(:value) { 'test_value' }
    let(:expires_in) { 10 }
    subject { described_class.new(:mock_client) }

    context 'normal flow' do
      it 'calls redis#setex with correct args' do
        expect(redis).to receive(:setex).with(key, expires_in, value)
        expect { subject.set(key, value, callback, expires_in: expires_in) }.not_to raise_error
      end
    end

    context 'when error raised' do
      it 'calls the callback' do
        expect(redis).to receive(:setex).with(key, expires_in, value).and_raise(Redis::TimeoutError)
        expect(callback).to receive(:call)
        expect { subject.set(key, value, callback, expires_in: expires_in) }.not_to raise_error
      end
    end
  end

  describe '#mapped_mset' do
    let(:callback) { Proc.new {} }
    let(:hash) { { 'key1' => 'val1', 'key2' => 'val2' } }
    subject { described_class.new(:mock_client) }

    context 'normal flow' do
      it 'calls redis#mset with correct args' do
        expect(redis).to receive(:mapped_mset).with(hash)
        expect { subject.mapped_mset(hash, callback) }.not_to raise_error
      end
    end

    context 'when error raised' do
      it 'calls the callback' do
        expect(redis).to receive(:mapped_mset).with(hash).and_raise(Redis::TimeoutError)
        expect(callback).to receive(:call)
        expect { subject.mapped_mset(hash, callback) }.not_to raise_error
      end
    end
  end
end
