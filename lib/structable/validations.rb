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
          constructor[attribute[:key]] ||= attribute[:default]
        end
      end
  
      def define_accessor_methods(constructor)
        self.class.attributes.each do |attribute|
          method_name = attribute[:alias_to] ? attribute[:alias_to].to_s : attribute[:key].to_s
          define_singleton_method(method_name) do
            value = constructor[attribute[:key]]
            attribute[:proc] ? attribute[:proc].call(value) : value
          end
        end
      end
  
      def validate_constructor(constructor)
        valid = self.class.attributes.all? do |attribute|
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

      def validate_presence(attribute, value)
        raise(Structable::ValidationError, "Required value #{attribute[:key]} not present") unless value
      end
  
      def validate_class(attribute, value)
        if attribute[:klass].nil? || attribute[:klass] == Structable::Any
          return
        elsif attribute[:klass] == Array && attribute[:of]
          valid = value.is_a?(Array) && value.all? { |v| v.class <= attribute[:of] }
          raise(Structable::ValidationError, "Class mismatch for #{attribute[:key]}. Should be an array with all #{attribute[:of]} elements.") unless valid
        else
          valid = [attribute[:klass]].flatten.compact.any? { |klass| value.class <= klass }
          raise(Structable::ValidationError, "Class mismatch for #{attribute[:key]} -> #{value.class}. Should be a #{attribute[:klass]}") unless valid
        end
      end
  
      def validate_one_of(attribute, value)
        valid = attribute[:one_of] ? options.include?(attribute[:one_of]) : true
        raise(Structable::ValidationError, "Value not one of #{attribute[:one_of].join(", ")}") unless valid
      end
  
      def validate_custom(attribute, value)
        valid = attribute[:validation] ? attribute[:validation].new(value).validate : true
        raise(Structable::ValidationError, "Custom validation #{attribute[:validation].to_s} not met") unless valid
      end

    end

    module ClassMethods

      def validate(key, klass = nil, kwargs = {}, &block)
        attribute_array = kwargs[:optional] ? optional_attributes : required_attributes
        attribute_array << {
          key: key,
          klass: klass,
          proc: block
        }.merge(kwargs.except(:key, :klass, :proc))
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
