require "structable/version"
require "custom_object_extensions"
require "structable/validation_error"
require "structable/validation"
require "structable/validations"
require "structable/mutations"
require "structable/hash"
require "structable/array"

module Structable
  class Any; end
  Boolean = [TrueClass, FalseClass]
  Number = [Integer, Float]
  Primitive = [String, Float, Integer, TrueClass, FalseClass]
end
