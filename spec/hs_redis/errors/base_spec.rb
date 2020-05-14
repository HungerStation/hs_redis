require 'spec_helper'

RSpec.describe HsRedis::Errors::Base do
  it 'should inherit StandardError class' do
    expect(described_class).to be < StandardError
  end
end