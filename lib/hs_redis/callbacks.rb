module HsRedis
  module Callbacks
    class RedisCallbacks
      def self.[](block)
        new.tap { |proxy| block.call(proxy) }
      end
  
      def respond_with(callback, *args)
        callbacks[callback].call(*args)
      end
  
      def method_missing(m, *args, &block)
        block ? callbacks[m] = block : super
        self
      end
  
      def callbacks
        @callbacks ||= {}
      end
    end
  end
end
