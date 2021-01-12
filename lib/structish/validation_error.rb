module Structish
  class ValidationError < RuntimeError
    def initialize(message, klass)
      super("#{message} in class #{klass.to_s}")
      set_backtrace(caller)
    end
  end
end
