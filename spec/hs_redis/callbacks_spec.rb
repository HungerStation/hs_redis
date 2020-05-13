require 'spec_helper'

RSpec.describe HsRedis::Callbacks::RedisCallbacks do
  describe '.tap_block' do
    it 'should self tap and call block' do
      block = Proc.new { 'do something' }
      response = described_class[block]
      expect(response.callbacks).to eq Hash.new
    end
  end

  describe '#respond_with' do
    it 'should return correct respond callback' do
      command = FFaker::Lorem.word
      block = Proc.new do |on|
        on.timeout do
          command
        end
      end
      response = described_class[block]
      expect(response.respond_with(:timeout)).to eq command
    end
  end
end