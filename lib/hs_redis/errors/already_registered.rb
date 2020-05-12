module HsRedis
  module Errors
    class AlreadyRegistered < Base
      def initialize(message: 'Client Already Registered, please choose differet name')
        super(message)
      end
    end
  end
end