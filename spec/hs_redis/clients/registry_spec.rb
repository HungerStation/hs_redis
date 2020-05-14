require 'spec_helper'

RSpec.describe HsRedis::Clients::Registry do
  let(:client) do
    ConnectionPool.new(size: rand(1..5), timeout: rand(1..10)) { redis }
  end
  let(:redis) { Redis.new }
  let!(:name) { FFaker::Lorem.word }

  before do
    allow(redis).to receive(:call).and_return(true)
  end
  after do
    described_class.unregister(name)
  end

  describe '#register_client' do
    context 'given non existing registered client' do
      it 'should success' do
        described_class.register_client(name, client)
        expect(described_class.registered_clients.size).to eq 1
      end
    end

    context 'given existing registered client' do
      before do
        described_class.register_client(name, client)
      end
      
      it 'should raise HsRedis::Errors::AlreadyRegistered' do
        expect { described_class.register_client(name, client) }.to raise_error(HsRedis::Errors::AlreadyRegistered)
      end
    end
  end

  describe '#register' do
    context 'given non existing registered client' do
      it 'should success' do
        described_class.register(name, pool_size: rand(1..5), timeout: rand(1..10), redis_uri: 'http://localhost', db: 0)
        expect(described_class.registered_clients.size).to eq 1
      end
    end

    context 'given existing registered client' do
      before do
        described_class.register(name, pool_size: rand(1..5), timeout: rand(1..10), redis_uri: 'http://localhost', db: 1)
      end
      
      it 'should raise HsRedis::Errors::AlreadyRegistered' do
        expect { described_class.register(name, pool_size: rand(1..5), timeout: rand(1..10), redis_uri: 'http://localhost', db: 0) }
          .to raise_error(HsRedis::Errors::AlreadyRegistered)
      end
    end

    context 'given redis not available' do
      before do
        allow(redis).to receive(:call).and_raise(Redis::TimeoutError)
      end

      it 'should raise HsRedis::Errors::Timeout' do
        expect do 
          described_class.register(name, pool_size: rand(1..5), timeout: rand(1..10), redis_uri: 'http://localhost', db: 0)
        end.to raise_error(HsRedis::Errors::Timeout)
      end
    end
  end

  describe '#unregister' do
    before do
      described_class.register_client(:name, client)
    end
    it 'should remove registered client' do
      expect(described_class.registered_clients.size).to eq 1

      described_class.unregister(:name)
      expect(described_class.registered_clients.size).to eq 0
    end
  end

  describe '#registered_clients' do
    let!(:names)do
      FFaker::Lorem.words
    end

    before do
      names.each do |client_name|
        described_class.register_client(client_name, client)
      end
    end

    after do
      names.each do |client_name|
        described_class.unregister(client_name)
      end
    end

    it 'should return registered client' do
      expect(described_class.registered_clients.size).to eq names.size
      expect(described_class.registered_clients.keys).to eq names.map{|value| value.to_sym}
    end
  end
end