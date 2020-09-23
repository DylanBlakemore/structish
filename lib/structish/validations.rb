module Structish
  module Validations

    def self.included base
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods

      def validate_structish(constructor)
        validate_key_restriction(constructor)
        cast_and_apply_defaults(constructor)
        validate_constructor(constructor)
        define_accessor_methods(constructor)
      end

      def validate_key_restriction(constructor)
        if self.class.restrict?
          allowed_keys = self.class.attributes.map { |attribute| attribute[:key] }
          valid = (constructor.keys - allowed_keys).empty?
          raise(Structish::ValidationError, "Keys are restricted to #{allowed_keys.join(", ")}") unless valid
        end
      end

      def cast_and_apply_defaults(constructor)
        self.class.optional_attributes.each do |attribute|
          key = attribute[:key]
          default_value = if attribute[:default].is_a?(::Array) && attribute[:default].first == :other_attribute
            constructor[attribute[:default][1]]
          else
            attribute[:default]
          end
          constructor[key] = default_value if constructor[key].nil?
        end

        (self.class.attributes + global_attributes_for(constructor)).each do |attribute|
          key = attribute[:key]
          if attribute[:cast] && constructor[key] && !constructor[key].is_a?(attribute[:klass])
            if cast_method = Structish::CAST_METHODS[attribute[:klass].to_s]
              constructor[key] = constructor[key].send(cast_method)
            else
              constructor[key] = attribute[:klass].new(constructor[key])
            end
          end
        end
      end
  
      def define_accessor_methods(constructor)
        self.class.attributes.each do |attribute|
          method_name = attribute[:alias_to] ? attribute[:alias_to].to_s : attribute[:key].to_s
          next if method_name.numerical?
          define_singleton_method(method_name) do
            value = constructor[attribute[:key]]
            attribute[:proc] ? attribute[:proc].call(value) : value
          end
        end
      end
  
      def validate_constructor(constructor)
        (self.class.attributes + global_attributes_for(constructor)).each do |attribute|
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
        @global_attributes ||= begin
          constructor_keys = constructor.keys
          self.class.global_validations.each_with_object([]) do |validation, arr|
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

    end

    module ClassMethods

      def delegate(key)
        [:other_attribute, key]
      end

      def restrict_attributes
        @restrict_attributes = true
      end

      def restrict?
        @restrict_attributes
      end

      def validate(key, klass = nil, kwargs = {}, &block)
        attribute_array = kwargs[:optional] ? optional_attributes : required_attributes
        attribute_array << attribute_hash(key, klass, kwargs, block)
      end

      def validate_all(klass = nil, kwargs = {}, &block)
        global_validations << attribute_hash(nil, klass, kwargs, block)
      end

      def attribute_hash(key, klass = nil, kwargs = {}, block)
        {
          key: key,
          klass: klass,
          proc: block
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

    end

  end
end
