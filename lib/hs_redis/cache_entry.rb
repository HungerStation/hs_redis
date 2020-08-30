module HsRedis
  class CacheEntry
    attr_reader :value

    def self.serialize(value)
      return if value.nil?
      Marshal.dump(self.new(value))
    end

    def self.parse(cache_entry)
      return if cache_entry.nil?
      Marshal.load(cache_entry).value
    end

    private

    def initialize(value)
      @value = value
    end
  end
end