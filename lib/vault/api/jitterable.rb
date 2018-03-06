module Vault
  module Jitterable
    def sleep_jitter( options = {} )
      if jitter_enabled?
        jitter_amount = jitter(options)
        sleep jitter_amount if jitter_amount > 0
      end
    end

    def jitter_enabled?
      jitter_size > 0
    end

    def jitter_size( options = {} )
      (options[:jitter_size] || client.options[:jitter_size]).to_i
    end

    def jitter_multiplier( options = {} )
      (options[:jitter_multiplier] || client.options[:jitter_multiplier]).to_f
    end

    def jitter( options = {} )
      if jitter_enabled?
        jitter_multiplier(options) * rand(jitter_size(options)).to_f / 1000.0
      else
        0
      end
    end
  end
end