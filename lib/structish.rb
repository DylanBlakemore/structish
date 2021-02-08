
require 'active_support/core_ext/hash'

require 'structish/config'

require "structish/version"
require "structish_object_extensions"
require "structish/validation_error"
require "structish/validation"
require "structish/validations"
require "structish/hash"
require "structish/array"

module Structish
  Any = nil
  Boolean = [TrueClass, FalseClass].freeze
  Number = [Integer, Float].freeze
  Primitive = [String, Float, Integer, TrueClass, FalseClass, Symbol].freeze

  CAST_METHODS = {
    "String" => :to_s,
    "Float" => :to_f,
    "Integer" => :to_i,
    "Hash" => :to_h,
    "Symbol" => :to_sym,
    "Array" => :to_a
  }.freeze

end
