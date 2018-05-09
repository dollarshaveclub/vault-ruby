module Vault
  module Cacheable
    def cache(url_path, cache_enabled)
      if cache_enabled && @cache[url_path]
        puts "cache hit"
        @cache[url_path]
      else
        puts "cache miss"
        @cache[url_path] = yield.dup
      end
    end
  end
end