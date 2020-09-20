module Structable
  class Hash < ::Hash

    include Structable::Validations

    def initialize(raw_constructor = {})
      constructor = self.class.symbolize? ? raw_constructor.symbolize_keys : raw_constructor
      validate_structable(constructor)

      if constructor.respond_to?(:to_hash)
        super()
        update(constructor)
        hash = constructor.to_hash
        self.default = hash.default if hash.default
        self.default_proc = hash.default_proc if hash.default_proc
      else
        super(constructor)
      end
    end

    def merge(other)
      self.class.new(super(other))
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
