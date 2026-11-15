module Ekylibre
  module Secret
    mattr_accessor :secret_file

    @@secret_file = Rails.root.join('config', 'api.yml')

    def self.store
      @@store ||= (secret_file.exist? ? YAML.safe_load_file(secret_file, permitted_classes: [Date, Time, Symbol], aliases: true) : {}).deep_symbolize_keys
    end

    def self.env
      @@env ||= Rails.env.to_sym
    end

    def self.find!(name)
      if store[name].is_a?(String)
        return store[name]
      elsif store[name].is_a?(Hash)
        return store[name][env]
      elsif store[env].is_a?(Hash)
        return store[env][name.to_s]
      end

      nil
    end
  end
end
