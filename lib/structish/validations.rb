module Structish
  module Validations

    def self.included base
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods

      def validate_structish(constructor)
        validate_key_restriction(constructor)
        apply_defaults(constructor)
        cast_values(constructor)
        validate_constructor(constructor)
        define_accessor_methods(constructor)
        define_delegated_methods
      end

      def define_delegated_methods
        self.class.delegations.each do |function, object|
          define_singleton_method(function.to_s) { self.send(object.to_sym)&.send(function.to_sym) }
        end
      end

      def validate_key_restriction(constructor)
        if self.class.restrict?
          allowed_keys = validations.map { |attribute| attribute[:key] }
          valid = (keys_for(constructor) - allowed_keys).empty?
          raise(Structish::ValidationError.new("Keys are restricted to #{allowed_keys.join(", ")}", self.class)) unless valid
        end
      end

      def apply_defaults(constructor)
        validations.select { |v| v[:optional] }.each do |attribute|
          key = attribute[:key]
          default_value = if attribute[:default].is_a?(::Array) && attribute[:default].first == :other_attribute
            constructor[attribute[:default][1]]
          else
            attribute[:default]
          end
          constructor[key] = default_value if constructor[key].nil?
        end
      end

      def cast_values(constructor)
        (validations + global_attributes_for(constructor)).each do |attribute|
          key = attribute[:key]
          if attribute[:cast] && constructor[key]
            if attribute[:klass] == ::Array && attribute[:of]
              unless constructor[key].class <= ::Array
                raise(Structish::ValidationError.new("Class mismatch for #{attribute[:key]} -> #{constructor[key].class}. Should be a Array", self.class))
              end
              constructor[key] = constructor[key].map { |v| cast_single(v, attribute[:of]) }
            else
              constructor[key] = cast_single(constructor[key], attribute[:klass])
            end
          end
        end
      end

      def cast_single(value, klass)
        if value.is_a?(klass)
          value
        else
          if cast_method = Structish::CAST_METHODS[klass.to_s]
            value.send(cast_method)
          else
            klass.new(value)
          end
        end
      end
  
      def define_accessor_methods(constructor)
        validations.each do |attribute|
          if accessor = attribute[:accessor]
            value = attribute[:proc] ? attribute[:proc].call(constructor[attribute[:key]]) : constructor[attribute[:key]]
            instance_variable_set "@#{accessor}", value
          end
        end
      end
  
      def validate_constructor(constructor)
        (validations + global_attributes_for(constructor)).each do |attribute|
          value = constructor[attribute[:key]]
          if attribute[:optional] && value.nil?
            true
          else
            validate_presence(attribute, value)
            validate_class(attribute, value)
            validate_one_of(attribute, value)
            validate_custom(attribute, value, constructor)
          end
        end
      end

      def global_attributes_for(constructor)
        global_attributes_hash[constructor] = begin
          constructor_keys = keys_for(constructor)
          global_validations.each_with_object([]) do |validation, arr|
            constructor_keys.each { |key| arr << validation.merge(key: key) }
          end
        end
      end

      def validate_presence(attribute, value)
        raise(Structish::ValidationError.new("Required value #{attribute[:key]} not present", self.class)) unless !value.nil?
      end
  
      def validate_class(attribute, value)
        if attribute[:klass].nil?
          return
        elsif attribute[:of]
          valid = if attribute[:klass] <= ::Array
            value.class <= ::Array && value.all? { |v| v.class <= attribute[:of] }
          elsif attribute[:klass] <= ::Hash
            value.class <= ::Hash && value.values.all? { |v| v.class <= attribute[:of] }
          end
          raise(Structish::ValidationError.new("Class mismatch for #{attribute[:key]}. All values should be of type #{attribute[:of].to_s}", self.class)) unless valid
        else
          valid_klasses = [attribute[:klass]].flatten.compact
          valid = valid_klasses.any? { |klass| value.class <= klass }
          raise(Structish::ValidationError.new("Class mismatch for #{attribute[:key]} -> #{value.class}. Should be a #{valid_klasses.join(", ")}", self.class)) unless valid
        end
      end

      def validate_one_of(attribute, value)
        valid = attribute[:one_of] ? attribute[:one_of].include?(value) : true
        raise(Structish::ValidationError.new("Value not one of #{attribute[:one_of].join(", ")}", self.class)) unless valid
      end
  
      def validate_custom(attribute, value, constructor)
        valid = attribute[:validation] ? attribute[:validation].new(value, attribute, constructor).validate : true
        raise(Structish::ValidationError.new("Custom validation #{attribute[:validation].to_s} not met", self.class)) unless valid
      end

      def []=(key, value)
        super(key, value)
        validate_structish(self)
      end

      def global_attributes_hash
        @global_attributes_hash ||= {}
      end

      def validations
        @validations ||= self.class.attributes + parent_attributes(self.class)
      end

      def global_validations
        @global_validations ||= self.class.global_validations + parent_global_validations(self.class)
      end

      def parent_attributes(klass)
        if klass.superclass.respond_to?(:structish?) && klass.superclass.structish?
          klass.superclass.attributes + parent_attributes(klass.superclass)
        end || []
      end

      def parent_global_validations(klass)
        if klass.superclass.respond_to?(:structish?) && klass.superclass.structish?
          klass.superclass.global_validations + parent_global_validations(klass.superclass)
        end || []
      end

      def attribute_values
        if self.class < Array
          self.to_a.values_at(*self.class.attribute_keys)
        elsif self.class < Hash
          self.to_h.slice(*self.class.attribute_keys)
        end
      end

      def keys_for(constructor)
        if constructor.class <= ::Array
          [*0..constructor.size-1]
        elsif constructor.class <= ::Hash
          constructor.keys
        end
      end

    end

    module ClassMethods

      def compact(do_compact)
        @compact = do_compact
      end

      def compact?
        @compact
      end

      def attribute_keys
        attributes.map { |attribute| attribute[:key] }
      end

      def structish?
        true
      end

      def delegate(function, object)
        delegations << [function, object]
      end

      def assign(key)
        [:other_attribute, key]
      end

      def restrict_attributes
        @restrict_attributes = true
      end

      def validate(key, klass = nil, kwargs = {}, &block)
        accessor_name = kwargs[:alias_to] ? kwargs[:alias_to] : key
        accessor = accessor_name.to_s if (accessor_name.is_a?(String) || accessor_name.is_a?(Symbol))
        attr_reader(accessor) if accessor
        attribute_array = kwargs[:optional] ? optional_attributes : required_attributes
        attribute_array << attribute_hash(key, klass, kwargs.merge(accessor: accessor), block)
      end

      def validate_all(klass = nil, kwargs = {}, &block)
        global_validations << attribute_hash(nil, klass, kwargs, block)
      end

      def attribute_hash(key, klass = nil, kwargs = {}, block)
        {
          key: key,
          klass: klass,
          proc: block,
        }.merge(kwargs.except(:key, :klass, :proc))
      end

      def global_validations
        @global_validations ||= []
      end

      def required_attributes
        @required_attributes ||= []
      end
  
      def optional_attributes
        @optional_attributes ||= []
      end
  
      def attributes
        required_attributes + optional_attributes
      end

      def delegations
        @delegations ||= []
      end

      def restrict?
        @restrict_attributes
      end

    end

  end
end
