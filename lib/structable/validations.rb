module Structable
  module Validations

    def self.included base
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods

      def validate_structable(constructor)
        apply_defaults(constructor)
        validate_constructor(constructor)
        define_accessor_methods(constructor)
      end

      def apply_defaults(constructor)
        self.class.optional_attributes.each do |attribute|
          constructor[attribute[:key]] = attribute[:default] if constructor[attribute[:key]].nil?
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
        constructor_keys = constructor.keys
        self.class.global_validations.each_with_object([]) do |validation, arr|
          constructor_keys.each do |key|
            arr << validation.merge(key: key)
          end
        end
      end

      def validate_presence(attribute, value)
        raise(Structable::ValidationError, "Required value #{attribute[:key]} not present") unless !value.nil?
      end
  
      def validate_class(attribute, value)
        if attribute[:klass].nil? || attribute[:klass] == Structable::Any
          return
        elsif attribute[:of]
          valid = if attribute[:klass] <= ::Array
            value.class <= ::Array && value.all? { |v| v.class <= attribute[:of] }
          elsif attribute[:klass] <= ::Hash
            value.class <= ::Hash && value.values.all? { |v| v.class <= attribute[:of] }
          end
          raise(Structable::ValidationError, "Class mismatch for #{attribute[:key]}. All values should be of type #{attribute[:of].to_s}") unless valid
        else
          valid_klasses = [attribute[:klass]].flatten.compact
          valid = valid_klasses.any? { |klass| value.class <= klass }
          raise(Structable::ValidationError, "Class mismatch for #{attribute[:key]} -> #{value.class}. Should be a #{valid_klasses.join(", ")}") unless valid
        end
      end
  
      def validate_one_of(attribute, value)
        valid = attribute[:one_of] ? options.include?(attribute[:one_of]) : true
        raise(Structable::ValidationError, "Value not one of #{attribute[:one_of].join(", ")}") unless valid
      end
  
      def validate_custom(attribute, value)
        valid = attribute[:validation] ? attribute[:validation].new(value, attribute).validate : true
        raise(Structable::ValidationError, "Custom validation #{attribute[:validation].to_s} not met") unless valid
      end

    end

    module ClassMethods

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
