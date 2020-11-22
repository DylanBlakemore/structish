module Structish
  class Validation

    attr_reader :value, :conditions, :constructor

    def initialize(value, conditions, constructor)
      @value = value
      @conditions = conditions
      @constructor = constructor
    end

    def validate
      raise(NotImplementedError, "Validation conditions function must be defined")
    end
  end
end
