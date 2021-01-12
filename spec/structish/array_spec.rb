require "spec_helper"

describe Structish::Array do
  let(:array_klass) do
    stub_const("SimpleStructishChild", Class.new(Structish::Array))
    SimpleStructishChild.class_eval do
      validate 0, Structish::Any, alias_to: :validated_key
    end
    SimpleStructishChild
  end
  let(:array_object) { array_klass.new(array) }
  let(:array) { [] }

  let(:array_klass_validate_all) do
    stub_const("ValidateAllClass", Class.new(Structish::Array))
    ValidateAllClass.class_eval do
      validate_all Float
    end
    ValidateAllClass
  end

  describe "#<<" do
    it "reruns the validations" do
      array_object = array_klass_validate_all.new([0.0])
      array_object << 5.0
      expect(array_object).to match([0.0, 5.0])
      expect { array_object << "foo" }.to raise_error
    end
  end

  describe "delegations" do
    context "when a function is delegated to an attribute" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, String, alias_to: :validated_key
          delegate :downcase, :validated_key
          delegate :upcase, :validated_key
        end
        SimpleStructishChild
      end

      it "creates the function correctly" do
        object = array_klass.new(["HeLlo"])
        expect(object.downcase).to eq("hello")
        expect(object.upcase).to eq("HELLO")
      end
    end

    context "when a delegation is assigned to an optional attribute and the attribute is nil" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, String, alias_to: :validated_key, optional: true
          delegate :downcase, :validated_key
          delegate :upcase, :validated_key
        end
        SimpleStructishChild
      end

      it "returns nil" do
        object = array_klass.new([])
        expect(object.downcase).to be_nil
        expect(object.upcase).to be_nil
      end
    end
  end

  describe "value reassignment" do
    let(:array_klass) do
      stub_const("SimpleStructishChild", Class.new(Structish::Array))
      SimpleStructishChild.class_eval do
        validate 0, Float, alias_to: :validated_key
      end
      SimpleStructishChild
    end

    let(:array_object) { array_klass.new([0.0]) }

    context "when the new value is valid" do
      it "does not raise an error" do
        array_object[0] = 5.0
        expect(array_object[0]).to eq(5.0)
        expect(array_object.validated_key).to eq(5.0)
      end
    end

    context "when the new value is invalid" do
      it "raises an error" do
        expect { array_object[0] = "5.0" }.to raise_error(Structish::ValidationError, "Class mismatch for 0 -> String. Should be a Float in class SimpleStructishChild")
      end
    end
  end

  describe "accessor mutations" do
    context "when an accessor mutation block is defined" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, Float, alias_to: :validated_key do |num|
            num * 2
          end
        end
        SimpleStructishChild
      end

      it "applies the block to the dynamic accessor method but not to the constructor object" do
        expect(array_klass.new([5.0])[0]).to eq(5.0)
        expect(array_klass.new([5.0]).validated_key).to eq(10.0)
      end
    end
  end

  describe "#dynamic accessor methods" do
    let(:array) { ["A validated key", "Not a validated key"] }

    it "create a method for the validated key" do
      expect(array_object[0]).to eq("A validated key")
      expect(array_object.validated_key).to eq("A validated key")
      expect(array_object[1]).to eq("Not a validated key")
      expect { array_object.non_validated_key }.to raise_error(NoMethodError)
    end
  end

  describe "attribute restrictions" do
    let(:array_klass) do
      stub_const("SimpleStructishChild", Class.new(Structish::Array))
      SimpleStructishChild.class_eval do
        validate 0, Float
        validate 1, Float, optional: true

        restrict_attributes
      end
      SimpleStructishChild
    end

    context "when the attributes are restricted" do
      context "when a subset of the attributes are present" do
        it "creates the object" do
          expect(array_klass.new([1.0]).to_a).to eq([1.0, nil])
          expect(array_klass.new([1.0, 2.0]).to_a).to eq([1.0, 2.0])
        end
      end

      context "when extra keys are present" do
        it "raises an appropriate error" do
          expect { array_klass.new([1.0, 2.0, 3.0]) }.to raise_error(Structish::ValidationError, "Keys are restricted to 0, 1 in class SimpleStructishChild")
        end
      end
    end
  end

  describe "defaults" do
    context "when a default is supplied for an optional attribute" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, Structish::Any, optional: true, default: 1, alias_to: :validated_key
        end
        SimpleStructishChild
      end

      context "when the attribute is nil" do
        it "applies the default" do
          expect(array_klass.new([]).validated_key).to eq(1)
          expect(array_klass.new([])[0]).to eq(1)
        end
      end

      context "when the attribute is present" do
        it "does not apply the default" do
          expect(array_klass.new([2]).validated_key).to eq(2)
          expect(array_klass.new([2])[0]).to eq(2)
        end
      end

      context "when the attribute is falsey but not nil" do
        it "does not apply the default" do
          expect(array_klass.new([false]).validated_key).to eq(false)
          expect(array_klass.new([false])[0]).to eq(false)
        end
      end

      context "when the default is defined as another attribute" do
        let(:array_klass) do
          stub_const("SimpleStructishChild", Class.new(Structish::Array))
          SimpleStructishChild.class_eval do
            validate 0, Structish::Any, optional: true, default: assign(1), alias_to: :validated_key
          end
          SimpleStructishChild
        end

        it "defaults the value to the value from the specified attribute" do
          expect(array_klass.new([nil, 1.0]).validated_key).to eq(1.0)
        end
      end
    end

    context "when a default is supplied for a required attribute" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, Structish::Any, default: 1
        end
        SimpleStructishChild
      end

      it "raises an error" do
        expect { array_klass.new([]) }.to raise_error(Structish::ValidationError, "Required value 0 not present in class SimpleStructishChild")
      end
    end
  end

  describe "cast to data type" do
    context "when the desired class is a standard data type" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, Float, cast: true
        end
        SimpleStructishChild
      end

      it "casts the value to the desired type" do
        expect(array_klass.new(["0.0"])[0]).to eq(0.0)
      end
    end

    context "for more complex data types" do
      let(:array_klass) do
        stub_const("CastClass", Class.new(Object))
        CastClass.class_eval do
          attr_accessor :member
          def initialize(m)
            @member = m
          end
        end

        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, CastClass, cast: true
        end
        SimpleStructishChild
      end

      it "uses Class.new to cast the value" do
        expect(array_klass.new([1])[0]).to be_a(CastClass)
      end
    end

    context "when an Array of classes is specified" do
      context "when the desired class is a standard data type" do
        let(:array_klass) do
          stub_const("SimpleStructishChild", Class.new(Structish::Array))
          SimpleStructishChild.class_eval do
            validate 0, ::Array, of: Float, cast: true, alias_to: :validated_key
          end
          SimpleStructishChild
        end

        it "casts each element of the array" do
          expect(array_klass.new([["0.0", 5.0, 9]]).validated_key).to eq([0.0, 5.0, 9.0])
        end
      end

      context "for more complex data types" do
        let(:array_klass) do
          stub_const("CastClass", Class.new(Object))
          CastClass.class_eval do
            attr_accessor :member
            def initialize(m)
              @member = m
            end
          end

          stub_const("SimpleStructishChild", Class.new(Structish::Array))
          SimpleStructishChild.class_eval do
            validate 0, ::Array, of: CastClass, cast: true, alias_to: :validated_key
          end
          SimpleStructishChild
        end

        it "casts each element of the array" do
          expect(array_klass.new([["0.0", 5.0, 9]]).validated_key.map(&:class)).to eq([CastClass, CastClass, CastClass])
        end
      end
    end
  end

  describe "custom data types" do
    describe "Any" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, Structish::Any, alias_to: :validated_key
        end
        SimpleStructishChild
      end

      it "allows any data type" do
        expect(array_klass.new([0.0]).validated_key).to eq(0.0)
        expect(array_klass.new(["hello"]).validated_key).to eq("hello")
        expect(array_klass.new([["hello"]]).validated_key).to eq(["hello"])
        expect(array_klass.new([{key: "value"}]).validated_key).to eq({key: "value"})
      end
    end

    describe "Boolean" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, Structish::Boolean, alias_to: :validated_key
        end
        SimpleStructishChild
      end

      it "allows TrueClass and FalseClass data types" do
        expect(array_klass.new([true]).validated_key).to eq(true)
        expect(array_klass.new([false]).validated_key).to eq(false)
        expect { array_klass.new([0.0]) }.to raise_error("Class mismatch for 0 -> Float. Should be a TrueClass, FalseClass in class SimpleStructishChild")
      end
    end

    describe "Number" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, Structish::Number, alias_to: :validated_key
        end
        SimpleStructishChild
      end

      it "allows float and integer data types" do
        expect(array_klass.new([0.0]).validated_key).to eq(0.0)
        expect(array_klass.new([1]).validated_key).to eq(1)
        expect { array_klass.new(["hello"]) }.to raise_error("Class mismatch for 0 -> String. Should be a Integer, Float in class SimpleStructishChild")
      end
    end

    describe "Primitive" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, Structish::Primitive, alias_to: :validated_key
        end
        SimpleStructishChild
      end

      it "allows primitive data types" do
        expect(array_klass.new([0.0]).validated_key).to eq(0.0)
        expect(array_klass.new([1]).validated_key).to eq(1)
        expect(array_klass.new([false]).validated_key).to eq(false)
        expect(array_klass.new([true]).validated_key).to eq(true)
        expect(array_klass.new(["hello"]).validated_key).to eq("hello")
        expect(array_klass.new([:hello]).validated_key).to eq(:hello)
        expect { array_klass.new([[]]) }.to raise_error("Class mismatch for 0 -> Array. Should be a String, Float, Integer, TrueClass, FalseClass, Symbol in class SimpleStructishChild")
      end
    end
  end

  describe "custom validations" do
    let(:array_klass) do
      stub_const("PositiveValidation", Class.new(Structish::Validation))
      PositiveValidation.class_eval do
        def validate
          value > 0
        end
      end

      stub_const("SimpleStructishChild", Class.new(Structish::Array))
      SimpleStructishChild.class_eval do
        validate 0, Structish::Number, validation: PositiveValidation
      end
      SimpleStructishChild
    end

    context "when the value satisifies the validation" do
      it "raises an appropriate error" do
        expect { array_klass.new([-1]) }.to raise_error(Structish::ValidationError, "Custom validation PositiveValidation not met in class SimpleStructishChild")
      end
    end

    context "when the value does not satisfy the validation" do
      it "creates the object" do
        expect(array_klass.new([1])[0]).to eq(1)
      end
    end
  end

  describe ".validate_all" do
    let(:array_klass) do
      stub_const("SimpleStructishChild", Class.new(Structish::Array))
      SimpleStructishChild.class_eval do
        validate_all Structish::Number
      end
      SimpleStructishChild
    end

    let(:instance) { array_klass.new(array) }

    context "when all the values match the conditions" do
      let(:array) { [1.0, 2] }

      it "creates the object" do
        expect(instance[0]).to eq(1.0)
        expect(instance[1]).to eq(2)
      end
    end

    context "when not all the values match the conditions" do
      let(:array) { [1.0, "two"] }

      it "raises an appropriate error" do
        expect { instance }.to raise_error(Structish::ValidationError, "Class mismatch for 1 -> String. Should be a Integer, Float in class SimpleStructishChild")
      end
    end
  end

  describe "#initialize" do
    context "when a non-array is passed to the constructor" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, Structish::Any, alias_to: :validated_key
        end
        SimpleStructishChild
      end

      it "raises an appropriate error" do
        expect { array_klass.new(1) }.to raise_error(ArgumentError, "Only array-like objects can be used as constructors for Structish::Array")
      end
    end

    context "when validating presence" do
      context "when the value is nil" do
        let(:array) { [nil, "Not a validated key"] }

        it "raises an appropriate validation error" do
          expect { array_object }.to raise_error(Structish::ValidationError, "Required value 0 not present in class SimpleStructishChild")
        end
      end

      context "when the value is blank but not nil" do
        let(:array) { ["", "Not a validated key"] }

        it "creates the object" do
          expect { array_object }.not_to raise_error
          expect(array_object.validated_key).to eq("")
        end
      end
    end

    context "when 'of' is specified for an array class" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, ::Array, of: String, alias_to: :validated_key
        end
        SimpleStructishChild
      end

      context "when the value is not an array" do
        let(:array) { ["hello"] }

        it "raises an appropriate error" do
          expect { array_object }.to raise_error(Structish::ValidationError, "Class mismatch for 0. All values should be of type String in class SimpleStructishChild")
        end
      end

      context "when some objects in the array are not of the appropriate type" do
        let(:array) { [["hello", 0.0]] }

        it "raises an appropriate error" do
          expect { array_object }.to raise_error(Structish::ValidationError, "Class mismatch for 0. All values should be of type String in class SimpleStructishChild")
        end
      end

      context "when all objects in the array are of the specified type" do
        let(:array) { [["hello", "world"]] }

        it "creates the object" do
          expect(array_object.validated_key).to eq(["hello", "world"])
        end
      end
    end

    context "when 'of' is specified for a hash class" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, ::Hash, of: String, alias_to: :validated_key
        end
        SimpleStructishChild
      end

      context "when the value is not a hash" do
        let(:array) { ["hello"] }

        it "raises an appropriate error" do
          expect { array_object }.to raise_error(Structish::ValidationError, "Class mismatch for 0. All values should be of type String in class SimpleStructishChild")
        end
      end

      context "when some objects in the hash are not of the appropriate type" do
        let(:array) { [{0 => "First", 1 => 1.0}] }

        it "raises an appropriate error" do
          expect { array_object }.to raise_error(Structish::ValidationError, "Class mismatch for 0. All values should be of type String in class SimpleStructishChild")
        end
      end

      context "when all objects in the hash are of the specified type" do
        let(:array) { [{0 => "First", 1 => "Second"}] }

        it "creates the object" do
          expect(array_object.validated_key).to eq({0 => "First", 1 => "Second"})
        end
      end
    end

    context "when validating class type" do
      let(:array_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Array))
        SimpleStructishChild.class_eval do
          validate 0, ::Hash, alias_to: :validated_key
        end
        SimpleStructishChild
      end

      context "when the value class is not a child of the specified class" do
        it "raises an appropriate validation error" do
          expect { array_klass.new(["hello"]) }.to raise_error(Structish::ValidationError, "Class mismatch for 0 -> String. Should be a Hash in class SimpleStructishChild")
        end
      end

      context "when the value class is equal to the specified class" do
        it "creates the object" do
          expect(array_klass.new([{zero: 0.0}]).validated_key).to eq({zero: 0.0})
        end
      end

      context "when the value class is a child of the specified class" do
        let(:dummy_child_class) { stub_const("DummyFloatChild", Class.new(::Hash)); DummyFloatChild }

        it "creates the object" do
          expect(array_klass.new([dummy_child_class.new({zero: 0.0})]).validated_key).to eq(dummy_child_class.new({zero: 0.0}))
        end
      end

      context "when an array of classes is specified" do
        let(:array_klass) do
          stub_const("SimpleStructishChild", Class.new(Structish::Array))
          SimpleStructishChild.class_eval do
            validate 0, [String, Float], alias_to: :validated_key
          end
          SimpleStructishChild
        end

        context "when the value class matches one of the classes" do
          it "creates the object" do
            expect(array_klass.new([0.0]).validated_key).to eq(0.0)
            expect(array_klass.new(["hello"]).validated_key).to eq("hello")
          end
        end

        context "when the value class does not match one of the classes" do
          it "raises an appropriate validation error" do
            expect { array_klass.new([:hello]) }.to raise_error(Structish::ValidationError, "Class mismatch for 0 -> Symbol. Should be a String, Float in class SimpleStructishChild")
          end
        end
      end
    end
  end
end
