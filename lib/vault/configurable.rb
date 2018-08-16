require_relative "defaults"

module Vault
  module Configurable
    def self.keys
      @keys ||= [
        :address,
        :token,
        :hostname,
        :open_timeout,
        :proxy_address,
        :proxy_password,
        :proxy_port,
        :proxy_username,
        :pool_size,
        :read_timeout,
        :ssl_ciphers,
        :ssl_pem_contents,
        :ssl_pem_file,
        :ssl_pem_passphrase,
        :ssl_ca_cert,
        :ssl_ca_path,
        :ssl_cert_store,
        :ssl_verify,
        :ssl_timeout,
        :timeout,
        :retry_options,
        :path_prefix,
        :jitter_multiplier,
        :jitter_size,
        :jitter_constant,
        :cache,
        :raise_on_not_found,
        :ignore_connection_errors,
        :k8s_auth_url_prefix
      ]
    end

    Vault::Configurable.keys.each(&method(:attr_accessor))

    # Configure yields self for block-style configuration.
    #
    # @yield [self]
    def configure
      yield self
    end

    # The list of options for this configurable.
    #
    # @return [Hash<Symbol, Object>]
    def options
      Hash[*Vault::Configurable.keys.map do |key|
        [key, instance_variable_get(:"@#{key}")]
      end.flatten(1)]
    end
  end
end
