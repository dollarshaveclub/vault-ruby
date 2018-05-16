module Vault
  module Cacheable
    def cache(url_path, cache_enabled)
      puts "CACHE READ: #{url_path} CACHED_ENABLED? #{cache_enabled}"
      if cache_enabled && @cache[url_path]
        puts "CACHE HIT: #{url_path} CACHED_ENABLED? #{cache_enabled}"
        @cache[url_path]
      else
        puts "CACHE MISS: #{url_path} CACHED_ENABLED? #{cache_enabled}"
        @cache[url_path] = yield.dup
      end
    end
  end
end