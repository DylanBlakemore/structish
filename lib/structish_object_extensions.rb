class ::Hash
  def to_structish(structish_klass)
    raise(ArgumentError, "Class is not a child of Structish::Hash") unless structish_klass < Structish::Hash
    structish_klass.new(self)
  end
end

class ::Array
  def to_structish(structish_klass)
    raise(ArgumentError, "Class is not a child of Structish::Array") unless structish_klass < Structish::Array
    structish_klass.new(self)
  end
end
