class HashWithIndifferentNumericalAccess < Hash
  def initialize(constructor = {})
    if constructor.respond_to?(:to_hash)
      super()
      update(constructor)
      hash = constructor.to_hash
      self.default = hash.default if hash.default
      self.default_proc = hash.default_proc if hash.default_proc
    else
      super(constructor)
    end
  end

  def [](key)
    value = keys_to_try(key).inject([]) { |arr, k| v = super(k); (arr << v) if v; arr }&.first
    if value.is_a?(Hash)
      value.with_indifferent_numerical_access
    else
      value
    end
  end

  def with_indifferent_numerical_access
    dup
  end

  def keys_to_try(key)
    to_try = [key, key.to_s]
    to_try = to_try + [key.to_f, key.to_f.to_s, key.to_i, key.to_i.to_s] if key.numerical?
    to_try.uniq
  end
end

class ::Hash
  def with_indifferent_numerical_access
    HashWithIndifferentNumericalAccess.new(self)
  end
end
