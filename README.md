# Structable

Structable objects are objects which maintain all the properties and methods of their parent classes, but add customisable validations, defaults, and mutations.

The concept came about when trying to create a data structure which could provide flexible validation for entries in a `Hash`; serve as a base class for inheritance so that further functions could be defined; and keep all the functionality of standard `Hash` objects.

Existing gems did not quite satisfy the requirements. [Dry::Struct](https://github.com/dry-rb/dry-struct) objects were found to be too rigid for the use cases, in that they do not allow additional keys to be defined other than the explicitly defined attributes. Furthermore, the biggest drawback is that `Dry::Struct` objects *are not hashes*. We wanted to keep all the functionality of hashes so that they would be both intuitive to use and highly flexible.

Other existing solutions generally fall into the `schema` pattern. Some type of schema is defined, and a method is added to the `Hash` object which allows one to validate against the schema. We still wanted a class-based inheritance system similar to `Dry::Struct`, in order to give more meaning to the objects we were creating. This in turn meant that continuous hash creation and validation would become tiresome and create less readable code.

So to summarise, the problem we were trying to solve needed a data structure that:
- Should be *rigid* enough to allow us to validate the data stored within the structure
- Should be *flexible* enough to allow us to define our own validations and methods, as well as allow for more than just the validated data to exist within the object
- Should be *functional* enough to still be used as a Hash (or other underlying base object)

The solution is a data structure which includes the functionality of `Hashes` (or `Arrays`), flexibility of `Schema` validations, and rigidity of `Structs` - the `Structable` object. When a class inherits from `Structable::Hash` or `Structable::Array`, it gains the ability to `validate` entries in the object. Properties which can be validated include the class type, value, and presence. Custom validations can also be added by creating a class which inherits from the `Structable::Validation` class and overriding the `validate` method.

Besides validating the constructor object, `Structable` objects also dynamically create accessor methods for the validated keys. So if we have `validate :foo` on the class, and an instance `obj` of that class, then we will have `obj.foo == constructor_hash[:foo]`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'structable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install structable

## Usage

### Creating Structable hashes and arrays

#### Class validation

There are two existing `Structable` classes: `Structable::Hash` and `Structable::Array`. Both follow similar usage. The simplest example is a hash which validates the classes of the keys:
```ruby
class MyStructableHash < Structable::Hash
    validate :foo, Float
end

# Validations
hash_klass.new({}) -> "Structable::ValidationError: Required value foo not present"
hash_klass.new({foo: "bar"}) -> "Structable::ValidationError: Class mismatch for foo -> String. Should be a Float"
hash_klass.new({foo: 1.0}) -> {:foo=>1.0}
hash_klass.new({foo: 1.0, bar: 2.0}) -> {:foo=>1.0, :bar=>2.0}

# Dynamic method creation
hash_klass.new({foo: 1.0, bar: 2.0}).foo -> 1.0
hash_klass.new({foo: 1.0, bar: 2.0})[:foo] -> 1.0
hash_klass.new({foo: 1.0, bar: 2.0}).foo -> "NoMethodError: undefined method `bar' for {:foo=>1.0, :bar=>2.0}:MyStructableHash"
hash_klass.new({foo: 1.0, bar: 2.0})[:bar] -> 1.0

# Inherited functionality
hash_klass.new({foo: 1.0}).merge(bar: 2.0) -> {:foo=>1.0, :bar=>2.0}
hash_klass.new({foo: 1.0}).merge(bar: 2.0).class -> MyStructableHash
```

From the above example we can see that the validation is checking two properties - presence and class. Since the `:foo` key is validated, it is by default required to create the object. If the validation conditions are not met, we get clear errors telling us what is failing the validation. This is how we introduce rigidity and struct-like behaviour into the object.

We can also see that `Structable` obects are not restrictive, since any keys can be added to the constructor hash, but only the specified keys are validated. This is where the flexibility comes in.

The example also shows how the dynamic accessor methods are assigned - although in the last two lines we are defining `{foo: 1.0, bar: 2.0}` as the constructor, we only get `.foo` as an accessor method. This is by design - the idea is that the validated entries will in general be expected - any other entries are extra details, and not necessary to fully describe the object.

Finally we can see how `Structable` objects inherit the functionality from the parent class. Standard Ruby hash functions can be used freely with the new Structable objects, and (where applicable) we will get a new object of the same type as the object on which we are performing the operation. This is where the deep functionality comes in.

#### Optional attributes

`Structable` object attributes can be flagged as optional. The usage should be fairly intuitive:
```ruby
class MyStructableHash < Structable::Hash
    validate :foo, Float, optional: true
end

hash_klass.new({}) -> {:foo=>nil}
hash_klass.new({}).foo -> nil
```

As shown above, when an attribute is missing from the constructor hash, the key gets added to the `Structable` object, and the accessor method is defined as usual.

#### Default values

When an attribute is flagged as optional, a default value can be assigned to the key. Assigning a default to a non-optional (required) key does nothing - instantiating the object without a required key will still raise an error, regardless of whether a default is defined.

```ruby
class MyStructableHash < Structable::Hash
    validate :foo, Float, optional: true, default: 1.0
end

hash_klass.new({}) -> {:foo=>1.0}
hash_klass.new({}).foo -> 1.0
```

```ruby
class MyStructableHash < Structable::Hash
    validate :foo, Float, default: 1.0
end

hash_klass.new({}) -> "Structable::ValidationError: Required value foo not present"
```


### Custom Structable 'classes'

There are four custom 'classes' available for validation:
- `Structable::Number` passes for `Integer` or `Float`
- `Structable::Boolean` passes for `TrueClass` or `FalseClass`
- `Structable::Primitive` passes for `TrueClass`, `FalseClass`, `String`, `Float`, or `Integer`
- `Structable::Any` passes for any class

Although these are used like classes, they are in fact constants in the `Structable` which are given values of an array of the relevant classes (or `nil` in the case of `Structable::Any`). This is for simplicity, since the standard validations can accept arrays of classes.

### Creating custom Structable classes


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/structable.
