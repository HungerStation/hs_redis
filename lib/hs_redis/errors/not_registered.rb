module HsRedis
  module Errors
    class NotRegistered < Base
      def initialize(message: 'Client Not Registered, please register in configuration')
        super(message)
      end
    end
  end
end