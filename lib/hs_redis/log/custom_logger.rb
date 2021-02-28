require 'json'
require 'logger'
module HsRedis
  module Log
    module CustomLogger
      def logit
        @@logger ||= Logger.new(STDOUT)
        @@logger.formatter = proc do |severity, datetime, _progname, msg|
          format = { level: severity, datetime: datetime.to_s, msg: msg, source: 'hs-redis-client'}
          if msg.is_a? Hash
            format.merge!(msg).reject!{ |k, _v| [:msg, :level].include? k }
          end
          JSON.generate(format) + $/
        end
        @@logger
      end
    end
  end
end
