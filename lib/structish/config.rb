module Structish
  class Config

    def self.config
      @config ||= {}.with_indifferent_access
    end

    def self.config=(config_hash)
      @config = config_hash.with_indifferent_access
    end

    def self.show_full_trace=(show_full)
      config["show_full_trace"] = show_full
    end

    def self.show_full_trace?
      config["show_full_trace"]
    end

  end
end
