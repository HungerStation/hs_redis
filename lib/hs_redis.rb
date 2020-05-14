require "hs_redis/version"

require "hs_redis/errors/base"
require "hs_redis/errors/already_registered"
require "hs_redis/errors/missing_parameter"
require "hs_redis/errors/timeout"
require "hs_redis/errors/proc_callback"
require "hs_redis/errors/not_registered"

require "hs_redis/clients/registry"

require "hs_redis/configuration"
require "hs_redis/callbacks"
require "hs_redis/store"

module HsRedis
  CONNECTION_REFUSED = 'ECONNREFUSED'.freeze
  OK = 'OK'.freeze
  NOT_FOUND = 'NOT_FOUND'.freeze
end
