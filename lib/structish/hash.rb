module Structish
  class Hash < ::Hash

    include Structish::Validations

    def initialize(raw_constructor = {})
      raise(ArgumentError, "Only hash-like objects can be used as constructors for Structish::Hash") unless raw_constructor.respond_to?(:to_hash)

      constructor = self.class.symbolize? ? raw_constructor.symbolize_keys : raw_constructor
      hash = constructor.to_h
      validate_structish(hash)
      hash = hash.compact if self.class.compact?
      super()
      update(hash)
      self.default = hash.default if hash.default
      self.default_proc = hash.default_proc if hash.default_proc
    end

    def merge(other)
      self.class.new(to_h.merge(other))
    end

    def merge!(other)
      super(other)
      validate_structish(self)
    end

    def except(*except_keys)
      self.class.new(to_h.except(*except_keys))
    end

    def except!(*except_keys)
      super(*except_keys)
      validate_structish(self)
    end

    def compact
      self.class.new(to_h.compact)
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
