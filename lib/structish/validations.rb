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
          define_singleton_method(function.to_s) { self.send(object.to_sym).send(function.to_sym) }
        end
      end

      def validate_key_restriction(constructor)
        if self.class.restrict?
          allowed_keys = self.class.attributes.map { |attribute| attribute[:key] }
          valid = (constructor.keys - allowed_keys).empty?
          raise(Structish::ValidationError, "Keys are restricted to #{allowed_keys.join(", ")}") unless valid
        end
      end

      def apply_defaults(constructor)
        self.class.optional_attributes.each do |attribute|
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
        (self.class.attributes + global_attributes_for(constructor)).each do |attribute|
          key = attribute[:key]
          if attribute[:cast] && constructor[key]
            if attribute[:klass] == ::Array && attribute[:of]
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
            validate_custom(attribute, value)
          end
        end
      end

      def global_attributes_for(constructor)
        global_attributes_hash[constructor] = begin
          constructor_keys = constructor.keys
          global_validations.each_with_object([]) do |validation, arr|
            constructor_keys.each { |key| arr << validation.merge(key: key) }
          end
        end
      end

      def validate_presence(attribute, value)
        raise(Structish::ValidationError, "Required value #{attribute[:key]} not present") unless !value.nil?
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
          raise(Structish::ValidationError, "Class mismatch for #{attribute[:key]}. All values should be of type #{attribute[:of].to_s}") unless valid
        else
          valid_klasses = [attribute[:klass]].flatten.compact
          valid = valid_klasses.any? { |klass| value.class <= klass }
          raise(Structish::ValidationError, "Class mismatch for #{attribute[:key]} -> #{value.class}. Should be a #{valid_klasses.join(", ")}") unless valid
        end
      end

      def validate_one_of(attribute, value)
        valid = attribute[:one_of] ? attribute[:one_of].include?(value) : true
        raise(Structish::ValidationError, "Value not one of #{attribute[:one_of].join(", ")}") unless valid
      end
  
      def validate_custom(attribute, value)
        valid = attribute[:validation] ? attribute[:validation].new(value, attribute).validate : true
        raise(Structish::ValidationError, "Custom validation #{attribute[:validation].to_s} not met") unless valid
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

    end

    module ClassMethods

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
