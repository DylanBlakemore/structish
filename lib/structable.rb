require "structable/version"
require "custom_object_extensions"
require "structable/validation_error"
require "structable/validation"
require "structable/validations"
require "structable/hash"
require "structable/array"

module Structable
  Any = nil
  Boolean = [TrueClass, FalseClass].freeze
  Number = [Integer, Float].freeze
  Primitive = [String, Float, Integer, TrueClass, FalseClass].freeze

  CAST_METHODS = {
    "String" => :to_s,
    "Float" => :to_f,
    "Integer" => :to_i,
    "Hash" => :to_h,
    "Symbol" => :to_sym,
    "Array" => :to_a
  }.freeze

end
