module Structable
  class Array < ::Array

    include Structable::Validations

    def initialize(constructor)
      validate_structable(constructor)
      super(constructor)
    end

  end
end
