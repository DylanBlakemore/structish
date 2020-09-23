module Structish
  class Array < ::Array

    include Structish::Validations

    def initialize(constructor)
      validate_structish(constructor)
      super(constructor)
    end

  end
end
