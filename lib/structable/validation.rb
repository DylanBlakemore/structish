module Structable
  class Validation

    attr_reader :value, :conditions

    def initialize(value, conditions)
      @value = value
      @conditions = conditions
    end

    def validate
      raise(NotImplementedError, "Validation conditions function must be defined")
    end
  end
end
