require 'json'
require 'logger'
module HsRedis
  module Log
    module CustomLogger
      def logit
        @@logger ||= Logger.new(STDOUT)
        @@logger.formatter = proc do |severity, datetime, progname, msg|
          {
            level: severity,
            timestamp: datetime.to_s,
            message: msg
          }.to_json + $/
        end
        @@logger
      end
    end
  end
end
