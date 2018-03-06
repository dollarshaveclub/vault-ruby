module Vault
  module Jitterable
    def sleep_jitter( options )
      if jitter_enabled?( options )
        jitter_amount = jitter(options)
        Kernel.sleep jitter_amount if jitter_amount > 0
      end
    end

    def jitter_enabled?( options )
      jitter_size( options ) > 0
    end

    def jitter_size( options )
      (options[:jitter_size] || client.options[:jitter_size]).to_i
    end

    def jitter_multiplier( options )
      (options[:jitter_multiplier] || client.options[:jitter_multiplier]).to_i
    end

    def jitter_constant( options )
      (options[:jitter_constant] || client.options[:jitter_constant]).to_i
    end

    def jitter( options )
      if jitter_enabled? options
        (jitter_constant(options) + jitter_multiplier(options).to_f * rand(jitter_size(options))).to_f / 1000.0
      else
        0
      end
    end
  end
end