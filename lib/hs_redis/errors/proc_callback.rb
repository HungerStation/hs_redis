module HsRedis
  module Errors
    class ProcCallback < Base
      def initialize(message: 'Callback should be a Proc')
        super(message)
      end
    end
  end
end