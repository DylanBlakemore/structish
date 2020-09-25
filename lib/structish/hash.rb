module Structish
  class Hash < ::Hash

    include Structish::Validations

    def initialize(raw_constructor = {})
      raise(ArgumentError, "Only hash-like objects can be used as constructors for Structish::Hash") unless raw_constructor.respond_to?(:to_hash)

      constructor = self.class.symbolize? ? raw_constructor.symbolize_keys : raw_constructor
      validate_structish(constructor)
      super()
      update(constructor)
      hash = constructor.to_hash
      self.default = hash.default if hash.default
      self.default_proc = hash.default_proc if hash.default_proc
    end

    def merge(other)
      self.class.new(to_h.merge(other))
    end

    protected

    def self.symbolize(sym)
      @symbolize = sym
    end

    def self.symbolize?
      @symbolize
    end

  end
end
