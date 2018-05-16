require_relative "secret"
require_relative "jitterable"
require_relative "cacheable"
require_relative "../client"
require_relative "../request"
require_relative "../response"

module Vault
  class Client
    # A proxy to the {Logical} methods.
    # @return [Logical]
    def logical
      @logical ||= Logical.new(self)
    end
    
    # A convenience method to Vault.logical.read with special logic to unwrap secrets with key of 'value'
    # example:  if a secret exists at secret/test/password contains the the payload: {"value": "password"}
    #           you can retrieve it via Vault.read_value('/secret/test/password') # "password"
    # @return [String]
    def read_value(path, options = {})
      result = logical.read(path, options)
      return nil if result.nil? || result.data.nil? || result.data[:value].nil?
      result.data[:value]
    end

    def full_path(path, options = {})
      logical.full_path path, options
    end
  end

  class Logical < Request
    include Vault::Jitterable
    include Vault::Cacheable
    
    # List the secrets at the given path, if the path supports listing. If the
    # the path does not exist, an exception will be raised.
    #
    # @example
    #   Vault.logical.list("secret") #=> [#<Vault::Secret>, #<Vault::Secret>, ...]
    #
    # @param [String] path
    #   the path to list
    #
    # @return [Array<String>]
    def list(path, options = {})
      headers = extract_headers!(options)
      json = client.list("/v1/#{encode_path(full_path(path, options))}", {}, headers)
      json[:data][:keys] || []
    rescue HTTPError => e
      if (options[:raise_on_not_found] || client.options[:raise_on_not_found]) && e.code == 404
        raise SecretNotFoundError.new(full_path(path, options))
      else 
        return []
      end
      raise
    end

    # Read the secret at the given path. If the secret does not exist, +nil+
    # will be returned.
    #
    # @example
    #   Vault.logical.read("secret/password") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] path
    #   the path to read
    #
    # @return [Secret, nil]
    def read(path, options = {})
      url_path = "/v1/#{encode_path(full_path(path, options))}"
      cache(url_path, options[:cache] || client.options[:cache]) do 
        puts "EXECUTING CACHE MISS BLOCK"
        sleep_jitter options
        headers = extract_headers!(options)
        json = client.get(url_path, {}, headers)
        Secret.decode(json)
      end
    rescue HTTPError => e
      if (options[:raise_on_not_found] || client.options[:raise_on_not_found]) && e.code == 404
        raise SecretNotFoundError.new(full_path(path, options))
      else 
        return nil
      end
      raise
    end

    # Write the secret at the given path with the given data. Note that the
    # data must be a {Hash}!
    #
    # @example
    #   Vault.logical.write("secret/password", value: "secret") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] path
    #   the path to write
    # @param [Hash] data
    #   the data to write
    #
    # @return [Secret]
    def write(path, data = {}, options = {})
      headers = extract_headers!(options)
      json = client.put("/v1/#{encode_path(full_path(path, options))}", JSON.fast_generate(data), headers)
      if json.nil?
        return true
      else
        return Secret.decode(json)
      end
    end

    # Delete the secret at the given path. If the secret does not exist, vault
    # will still return true.
    #
    # @example
    #   Vault.logical.delete("secret/password") #=> true
    #
    # @param [String] path
    #   the path to delete
    #
    # @return [true]
    def delete(path)
      client.delete("/v1/#{encode_path(full_path(path))}")
      return true
    end

    
    def full_path(path, options = {})
      prefix = options[:path_prefix] || client.options[:path_prefix]
      [prefix, path].compact.join('/').gsub /\/+/, '/'
    end

    # Unwrap the data stored against the given token. If the secret does not
    # exist, `nil` will be returned.
    #
    # @example
    #   Vault.logical.unwrap("f363dba8-25a7-08c5-430c-00b2367124e6") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] wrapper
    #   the token to use when unwrapping the value
    #
    # @return [Secret, nil]
    def unwrap(wrapper)
      client.with_token(wrapper) do |client|
        json = client.get("/v1/cubbyhole/response")
        secret = Secret.decode(json)

        # If there is nothing in the cubbyhole, return early.
        if secret.nil? || secret.data.nil? || secret.data[:response].nil?
          return nil
        end

        # Extract the response and parse it into a new secret.
        json = JSON.parse(secret.data[:response], symbolize_names: true)
        secret = Secret.decode(json)
        return secret
      end
    rescue HTTPError => e
      if (options[:raise_on_not_found] || client.options[:raise_on_not_found]) && e.code == 404
        raise SecretNotFoundError.new(full_path(path, options))
      else 
        return nil
      end
      raise
    end

    # Unwrap a token in a wrapped response given the temporary token.
    #
    # @example
    #   Vault.logical.unwrap("f363dba8-25a7-08c5-430c-00b2367124e6") #=> "0f0f40fd-06ce-4af1-61cb-cdc12796f42b"
    #
    # @param [String, Secret] wrapper
    #   the token to unwrap
    #
    # @return [String, nil]
    def unwrap_token(wrapper)
      # If provided a secret, grab the token. This is really just to make the
      # API a bit nicer.
      if wrapper.is_a?(Secret)
        wrapper = wrapper.wrap_info.token
      end

      # Unwrap
      response = unwrap(wrapper)

      # If nothing was there, return nil
      if response.nil? || response.auth.nil?
        return nil
      end

      return response.auth.client_token
    rescue HTTPError => e
      raise
    end
  end
end
