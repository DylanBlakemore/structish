module Structish
  class ValidationError < RuntimeError
    def initialize(message, klass)
      super("#{message} in class #{klass.to_s}")
      set_backtrace(caller)
      if Config.show_full_trace?
        puts self.backtrace
      end
    end
  end
end
