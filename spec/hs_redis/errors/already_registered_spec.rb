require 'spec_helper'

RSpec.describe HsRedis::Errors::AlreadyRegistered do
  it 'should inherit HsRedis::Errors::Base' do
    expect(described_class).to be < HsRedis::Errors::Base
  end
end