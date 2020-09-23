# Structish

Structish objects are objects which maintain all the properties and methods of their parent classes, but add customisable validations, defaults, and mutations.

The concept came about when trying to create a data structure which could provide flexible validation for entries in a `Hash`; serve as a base class for inheritance so that further functions could be defined; and keep all the functionality of standard `Hash` objects.

Existing gems did not quite satisfy the requirements. [Dry::Struct](https://github.com/dry-rb/dry-struct) objects were found to be too rigid for the use cases, in that they do not allow additional keys to be defined other than the explicitly defined attributes. Furthermore, the biggest drawback is that `Dry::Struct` objects *are not hashes*. We wanted to keep all the functionality of hashes so that they would be both intuitive to use and highly flexible.

Other existing solutions generally fall into the `schema` pattern. Some type of schema is defined, and a method is added to the `Hash` object which allows one to validate against the schema. We still wanted a class-based inheritance system similar to `Dry::Struct`, in order to give more meaning to the objects we were creating. This in turn meant that continuous hash creation and validation would become tiresome and create less readable code.

So to summarise, the problem we were trying to solve needed a data structure that:
- Should be *rigid* enough to allow us to validate the data stored within the structure
- Should be *flexible* enough to allow us to define our own validations and methods, as well as allow for more than just the validated data to exist within the object
- Should be *functional* enough to still be used as a Hash (or other underlying base object)

The solution is a data structure which includes the functionality of `Hashes` (or `Arrays`), flexibility of `Schema` validations, and rigidity of `Structs` - the `Structish` object. When a class inherits from `Structish::Hash` or `Structish::Array`, it gains the ability to `validate` entries in the object. Properties which can be validated include the class type, value, and presence. Custom validations can also be added by creating a class which inherits from the `Structish::Validation` class and overriding the `validate` method.

Besides validating the constructor object, `Structish` objects also dynamically create accessor methods for the validated keys. So if we have `validate :foo` on the class, and an instance `obj` of that class, then we will have `obj.foo == constructor_hash[:foo]`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'structish'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install structish

## Usage

### Creating Structish hashes and arrays

#### Class validation

There are two existing `Structish` classes: `Structish::Hash` and `Structish::Array`. Both follow similar usage. The simplest example is a hash which validates the classes of the keys:
```ruby
class MyStructishHash < Structish::Hash
    validate :foo, Float
end

# Validations
MyStructishHash.new({}) -> "Structish::ValidationError: Required value foo not present"
MyStructishHash.new({foo: "bar"}) -> "Structish::ValidationError: Class mismatch for foo -> String. Should be a Float"
MyStructishHash.new({foo: 1.0}) -> {:foo=>1.0}
MyStructishHash.new({foo: 1.0, bar: 2.0}) -> {:foo=>1.0, :bar=>2.0}

# Dynamic method creation
MyStructishHash.new({foo: 1.0, bar: 2.0}).foo -> 1.0
MyStructishHash.new({foo: 1.0, bar: 2.0})[:foo] -> 1.0
MyStructishHash.new({foo: 1.0, bar: 2.0}).foo -> "NoMethodError: undefined method `bar' for {:foo=>1.0, :bar=>2.0}:MyStructishHash"
MyStructishHash.new({foo: 1.0, bar: 2.0})[:bar] -> 1.0

# Inherited functionality
MyStructishHash.new({foo: 1.0}).merge(bar: 2.0) -> {:foo=>1.0, :bar=>2.0}
MyStructishHash.new({foo: 1.0}).merge(bar: 2.0).class -> MyStructishHash
```

From the above example we can see that the validation is checking two properties - presence and class. Since the `:foo` key is validated, it is by default required to create the object. If the validation conditions are not met, we get clear errors telling us what is failing the validation. This is how we introduce rigidity and struct-like behaviour into the object.

We can also see that `Structish` obects are not restrictive, since any keys can be added to the constructor hash, but only the specified keys are validated. This is where the flexibility comes in.

The example also shows how the dynamic accessor methods are assigned - although in the last two lines we are defining `{foo: 1.0, bar: 2.0}` as the constructor, we only get `.foo` as an accessor method. This is by design - the idea is that the validated entries will in general be expected - any other entries are extra details, and not necessary to fully describe the object.

Finally we can see how `Structish` objects inherit the functionality from the parent class. Standard Ruby hash functions can be used freely with the new Structish objects, and (where applicable) we will get a new object of the same type as the object on which we are performing the operation. This is where the deep functionality comes in.

Note that the required class can be an array, and will pass if the value is an instance of one of the classes in the array.

When the required class is a `Array`, we can define a further requirement using the `of:` keyword to validate each element of the value array.

```ruby
class MyStructishHash < Structish::Hash
    validate :foo, ::Array, of: Float
end

MyStructishHash.new({foo: 1.0}) -> "Structish::ValidationError: Class mismatch for foo. All values should be of type Float"
MyStructishHash.new({foo: [1.0, "bar"]}) -> "Structish::ValidationError: Class mismatch for foo. All values should be of type Float"
MyStructishHash.new({foo: [1.0, 2.0]}) -> {:foo=>[1.0, 2.0]}
```

#### Optional attributes

`Structish` object attributes can be flagged as optional. The usage should be fairly intuitive:
```ruby
class MyStructishHash < Structish::Hash
    validate :foo, Float, optional: true
end

MyStructishHash.new({}) -> {:foo=>nil}
MyStructishHash.new({}).foo -> nil
```

As shown above, when an attribute is missing from the constructor hash, the key gets added to the `Structish` object, and the accessor method is defined as usual.

#### Default values

When an attribute is flagged as optional, a default value can be assigned to the key. Assigning a default to a non-optional (required) key does nothing - instantiating the object without a required key will still raise an error, regardless of whether a default is defined.

```ruby
class MyStructishHash < Structish::Hash
    validate :foo, Float, optional: true, default: 1.0
end

MyStructishHash.new({}) -> {:foo=>1.0}
MyStructishHash.new({}).foo -> 1.0
```

```ruby
class MyStructishHash < Structish::Hash
    validate :foo, Float, default: 1.0
end

MyStructishHash.new({}) -> "Structish::ValidationError: Required value foo not present"
```

A useful feature of the default option is that you can map the value from one key to the default value:

```ruby
class MyStructishHash < Structish::Hash
    validate :foo, Float
    validate :bar, Float, optional: true, default: delegate(:foo)
end

MyStructishHash.new({foo: 1.0}) -> {:foo=>1.0, :bar=>1.0}
MyStructishHash.new({foo: 1.0}).foo -> 1.0
MyStructishHash.new({foo: 1.0}).bar -> 1.0
```

#### Type casting

`Structish` validations support forced type-casting. This occurs *before* data type validation, which means that we can potentially pass in an object which is not of the required class, but force type casting so that it passes the validation:

```ruby
class StructishHashWithoutCasting < Structish::Hash
    validate :foo, Float
end

StructishHashWithoutCasting.new({foo: "1"}) -> "Structish::ValidationError: Class mismatch for foo -> String. Should be a Float"

class StructishHashWithCasting < Structish::Hash
    validate :foo, Float, cast: Float
end

StructishHashWithCasting.new({foo: "1"}) -> {:foo=>1.0}
StructishHashWithCasting.new({foo: "1"}).foo -> 1.0
StructishHashWithCasting.new({foo: {}}) -> "NoMethodError: undefined method `to_f' for {}:Hash"
```

For common Ruby types (specifically `String, Float, Integer, Symbol, Array, Hash`) this uses the relevant `to_x` function, namely `to_s, to_f, to_i, to_sym, to_a, to_h` respectively. For any custom classes, this will call `Klass.new(value)`.

#### Specific values

`Structish` objects are not limited to validating classes and presence - they can also validate specific values, using the `one_of:` key:

```ruby
class MyStructishHash < Structish::Hash
    validate :foo, Float, one_of: [0.0, 1.0, 2.0]
end

MyStructishHash.new({foo: 1.0}) -> {:foo=>1.0}
MyStructishHash.new({foo: 5.0}) -> "Structish::ValidationError: Value not one of 0.0, 1.0, 2.0"
```

#### Global validations

`Structable` objects allow for validations at the global level, i.e. validations that apply to every value in the object. Global validations are defined almost identically to individual validations, with the exception that they do not specify the key:

```ruby
class MyStructishHash < Structish::Hash
    validate_all Float
end

MyStructishHash.new({foo: 1.0, bar: 2.0}) -> {:foo=>1.0, :bar=>2.0}
MyStructishHash.new({foo: 1.0, bar: "2.0"}) -> "Structish::ValidationError: Class mismatch for bar -> String. Should be a Float"
```

The `validate_all` function can perform all the same validations as the individual validations, and can also be mixed and matched with individual validations.

#### Accessor block mutations

A nifty feature of `Structish` object is, within the validation, we can define a block which mutates the output of the dynamic accessor method:

```ruby
class MyStructishHash < Structish::Hash
    validate :foo, Float, do |num|
        num * 2
    end
end

MyStructishHash.new(validated_key: 5.0)[:validated_key] -> 5.0
MyStructishHash.new(validated_key: 5.0).validated_key -> 10.0
```

It is important to realize that the mutation *only applies to the dynamically created accessor method*. We still want to allow access to the original data - the idea here is that the accessor method can perform any operations on the original value, while the hash version stores the original data.

### Custom validations

We can define custom validations, which may contain any logic that returns a truthy or falsey value. The validation class must inherit from `Structish::Validation` and must override the `validate` method. The accessible attribute to the class are `value` and `conditions` - `value` is the value detected for that key, and `conditions` are the conditions defined in the validation on the class.

```ruby
class PositiveNumber < Structish::Validation
    def validate
        value > 0
    end
end

class MyStructishHash < Structish::Hash
    validate :foo, Float, validation: PositiveNumber
end

MyStructishHash.new({foo: 0.0}) -> "Structish::ValidationError: Custom validation PositiveNumberStructishValidation not met"
MyStructishHash.new({foo: 1.0}) -> {:foo=>1.0}
```

### Custom Structish data types

There are four custom 'classes' available for validation:
- `Structish::Number` passes for `Integer` or `Float`
- `Structish::Boolean` passes for `TrueClass` or `FalseClass`
- `Structish::Primitive` passes for `TrueClass`, `FalseClass`, `String`, `Float`, or `Integer`
- `Structish::Any` passes for any class

Although these are used like classes, they are in fact constants in the `Structish` which are given values of an array of the relevant classes (or `nil` in the case of `Structish::Any`). This is for simplicity, since the standard validations can accept arrays of classes.

### Creating custom Structish classes


### Structish::Hash methods


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/Structish.
