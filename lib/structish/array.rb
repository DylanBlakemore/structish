module Structish
  class Array < ::Array

    include Structish::Validations

    def initialize(constructor)
      raise(ArgumentError, "Only array-like objects can be used as constructors for Structish::Array") unless constructor.class <= ::Array
      validate_structish(constructor)
      super(constructor)
    end

  end
end
