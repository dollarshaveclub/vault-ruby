module Vault
  module Cacheable
    def cache(url_path, cache_enabled)
      if cache_enabled && @cache[url_path]
        @cache[url_path]
      else
        @cache[url_path] = yield.dup
      end
    end
  end
end