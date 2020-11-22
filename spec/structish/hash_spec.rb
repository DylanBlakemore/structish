require "spec_helper"

describe Structish::Hash do

  let(:hash_klass) do
    stub_const("SimpleStructishChild", Class.new(Structish::Hash))
    SimpleStructishChild.class_eval do
      validate :validated_key
    end
    SimpleStructishChild
  end
  let(:hash_object) { hash_klass.new(hash) }
  let(:hash) { {} }

  describe "inheritance" do
    let(:parent_hash_klass) do
      stub_const("SimpleStructishParent", Class.new(Structish::Hash))
      SimpleStructishParent.class_eval do
        validate :validated_key
      end
      SimpleStructishParent
    end

    let(:child_hash_klass) do
      stub_const("SimpleStructishChildChild", Class.new(parent_hash_klass))
      SimpleStructishChildChild.class_eval do
        validate :another_validated_key, Float
      end
      SimpleStructishChildChild
    end

    context "when one structish implementation inherits from another" do
      let(:hash_object) { child_hash_klass.new(validated_key: 0, another_validated_key: 1.0) }

      it "inherits the validation methods from the parent class" do
        expect(hash_object.validated_key).to eq(0)
        expect(hash_object.another_validated_key).to eq(1.0)
      end

      context "with default options" do
        let(:parent_hash_klass) do
          stub_const("SimpleStructishParent", Class.new(Structish::Hash))
          SimpleStructishParent.class_eval do
            validate :validated_key, Structish::Any, optional: true, default: 5.0
          end
          SimpleStructishParent
        end

        let(:hash_object) { child_hash_klass.new(another_validated_key: 1.0) }

        it "applies the defaults correctly" do
          expect(hash_object.validated_key).to eq(5.0)
          expect(hash_object.another_validated_key).to eq(1.0)
        end
      end

      context "with casting" do
        let(:parent_hash_klass) do
          stub_const("SimpleStructishParent", Class.new(Structish::Hash))
          SimpleStructishParent.class_eval do
            validate :validated_key, Float, cast: true
          end
          SimpleStructishParent
        end

        let(:hash_object) { child_hash_klass.new(validated_key: "10", another_validated_key: 1.0) }

        it "casts the values correctly" do
          expect(hash_object.validated_key).to eq(10.0)
          expect(hash_object.another_validated_key).to eq(1.0)
        end
      end
    end
  end

  describe "delegations" do
    context "when a function is delegated to an attribute" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, String
          delegate :downcase, :validated_key
          delegate :upcase, :validated_key
        end
        SimpleStructishChild
      end

      it "creates the function correctly" do
        object = hash_klass.new(validated_key: "HeLlo")
        expect(object.downcase).to eq("hello")
        expect(object.upcase).to eq("HELLO")
      end
    end

    context "when a delegation is assigned to an optional attribute and the attribute is nil" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, String, optional: true
          delegate :downcase, :validated_key
          delegate :upcase, :validated_key
        end
        SimpleStructishChild
      end

      it "returns nil" do
        object = hash_klass.new({})
        expect(object.downcase).to be_nil
        expect(object.upcase).to be_nil
      end
    end
  end

  describe "#merge" do
    it "returns an instance of the structish class" do
      expect(hash_klass.new(validated_key: 1).merge(unvalidated_key: 2)).to be_a(SimpleStructishChild)
      expect { hash_klass.new(validated_key: 1).merge(validated_key: nil) }.to raise_error(Structish::ValidationError, "Required value validated_key not present")
    end
  end

  describe "#merge!" do
    it "updates the hash and runs the validations" do
      structish_object = hash_klass.new(validated_key: 1)
      structish_object.merge!(unvalidated_key: 2)
      expect(structish_object).to match({validated_key: 1, unvalidated_key: 2})
      expect { structish_object.merge!(validated_key: nil) }.to raise_error(Structish::ValidationError, "Required value validated_key not present")
    end
  end

  describe "#except" do
    it "returns an instance of the structish class" do
      expect(hash_klass.new(validated_key: 1, unvalidated_key: 2).except(:unvalidated_key)).to be_a(SimpleStructishChild)
      expect(hash_klass.new(validated_key: 1, unvalidated_key: 2).except(:unvalidated_key)).to match({validated_key: 1})
      expect { hash_klass.new(validated_key: 1, unvalidated_key: 2).except(:validated_key) }.to raise_error(Structish::ValidationError, "Required value validated_key not present")
    end
  end

  describe "#except!" do
    it "updates the hash and runs the validations" do
      structish_object = hash_klass.new(validated_key: 1, unvalidated_key: 2)
      structish_object.except!(:unvalidated_key)
      expect(structish_object).to match({validated_key: 1})
      expect { structish_object.except!(:validated_key) }.to raise_error(Structish::ValidationError, "Required value validated_key not present")
    end
  end

  describe "#compact" do
    it "updates the hash and runs the validations" do
      structish_object = hash_klass.new(validated_key: 1, unvalidated_key: 2, something_else: nil)
      expect(structish_object.keys).to include(:something_else)
      expect(structish_object.compact.keys).not_to include(:something_else)
      expect(structish_object.compact).to be_a(hash_klass)
    end
  end

  describe "value reassignment" do
    let(:hash_klass) do
      stub_const("SimpleStructishChild", Class.new(Structish::Hash))
      SimpleStructishChild.class_eval do
        validate :validated_key, Float
      end
      SimpleStructishChild
    end

    let(:hash_object) { hash_klass.new(validated_key: 0.0) }

    context "when the new value is valid" do
      it "does not raise an error" do
        hash_object[:validated_key] = 5.0
        expect(hash_object[:validated_key]).to eq(5.0)
        expect(hash_object.validated_key).to eq(5.0)
      end
    end

    context "when the new value is invalid" do
      it "raises an error" do
        expect { hash_object[:validated_key] = "5.0" }.to raise_error(Structish::ValidationError, "Class mismatch for validated_key -> String. Should be a Float")
      end
    end
  end

  describe "accessor mutations" do
    context "when an accessor mutation block is defined" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, Float do |num|
            num * 2
          end
        end
        SimpleStructishChild
      end

      it "applies the block to the dynamic accessor method but not to the constructor object" do
        expect(hash_klass.new(validated_key: 5.0)[:validated_key]).to eq(5.0)
        expect(hash_klass.new(validated_key: 5.0).validated_key).to eq(10.0)
      end
    end
  end

  describe "#dynamic accessor methods" do
    let(:hash) { {validated_key: "A validated key", non_validated_key: "Not a validated key"} }

    it "create a method for the validated key" do
      expect(hash_object[:validated_key]).to eq("A validated key")
      expect(hash_object.validated_key).to eq("A validated key")
      expect(hash_object[:non_validated_key]).to eq("Not a validated key")
      expect { hash_object.non_validated_key }.to raise_error(NoMethodError)
    end

    context "when an alias is defined" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, Float, alias_to: :float_value
        end
        SimpleStructishChild
      end

      let(:hash) { {validated_key: 0.0} }

      it "renames the accessor method to the alias value" do
        expect(hash_object.float_value).to eq(0.0)
        expect { hash_object.validated_key }.to raise_error(NoMethodError)
      end
    end
  end

  describe "attribute restrictions" do
    let(:hash_klass) do
      stub_const("SimpleStructishChild", Class.new(Structish::Hash))
      SimpleStructishChild.class_eval do
        validate :validated_key, Float
        validate :other_validated_key, Float, optional: true

        restrict_attributes
      end
      SimpleStructishChild
    end

    context "when the attributes are restricted" do
      context "when a subset of the attributes are present" do
        it "creates the object" do
          expect(hash_klass.new({validated_key: 1.0}).to_h).to eq({validated_key: 1.0, other_validated_key: nil})
          expect(hash_klass.new({validated_key: 1.0, other_validated_key: 2.0}).to_h).to eq({validated_key: 1.0, other_validated_key: 2.0})
        end
      end

      context "when extra keys are present" do
        it "raises an appropriate error" do
          expect { hash_klass.new({validated_key: 1.0, unreal_key: 3.0}) }.to raise_error(Structish::ValidationError, "Keys are restricted to validated_key, other_validated_key")
        end
      end
    end
  end

  describe "defaults" do
    context "when a default is supplied for an optional attribute" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, Structish::Any, optional: true, default: 1
        end
        SimpleStructishChild
      end

      context "when the attribute is nil" do
        it "applies the default" do
          expect(hash_klass.new({}).validated_key).to eq(1)
          expect(hash_klass.new({})[:validated_key]).to eq(1)
        end
      end

      context "when the attribute is present" do
        it "does not apply the default" do
          expect(hash_klass.new({validated_key: 2}).validated_key).to eq(2)
          expect(hash_klass.new({validated_key: 2})[:validated_key]).to eq(2)
        end
      end

      context "when the attribute is falsey but not nil" do
        it "does not apply the default" do
          expect(hash_klass.new({validated_key: false}).validated_key).to eq(false)
          expect(hash_klass.new({validated_key: false})[:validated_key]).to eq(false)
        end
      end

      context "when the default is defined as another attribute" do
        let(:hash_klass) do
          stub_const("SimpleStructishChild", Class.new(Structish::Hash))
          SimpleStructishChild.class_eval do
            validate :validated_key, Structish::Any, optional: true, default: assign(:unvalidated_key)
          end
          SimpleStructishChild
        end

        it "defaults the value to the value from the specified attribute" do
          expect(hash_klass.new(unvalidated_key: 1.0).validated_key).to eq(1.0)
        end
      end
    end

    context "when a default is supplied for a required attribute" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, Structish::Any, default: 1
        end
        SimpleStructishChild
      end

      it "raises an error" do
        expect { hash_klass.new({}) }.to raise_error(Structish::ValidationError, "Required value validated_key not present")
      end
    end
  end

  describe "cast to data type" do
    context "when the desired class is a standard data type" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, Float, cast: true
        end
        SimpleStructishChild
      end

      it "casts the value to the desired type" do
        expect(hash_klass.new({validated_key: "0.0"})[:validated_key]).to eq(0.0)
      end
    end

    context "for more complex data types" do
      let(:hash_klass) do
        stub_const("CastClass", Class.new(Object))
        CastClass.class_eval do
          attr_accessor :member
          def initialize(m)
            @member = m
          end
        end

        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, CastClass, cast: true
        end
        SimpleStructishChild
      end

      it "uses Class.new to cast the value" do
        expect(hash_klass.new({validated_key: 1}).validated_key).to be_a(CastClass)
      end
    end

    context "when an Array of classes is specified" do
      context "when the desired class is a standard data type" do
        let(:hash_klass) do
          stub_const("SimpleStructishChild", Class.new(Structish::Hash))
          SimpleStructishChild.class_eval do
            validate :validated_key, ::Array, of: Float, cast: true
          end
          SimpleStructishChild
        end

        it "casts each element of the array" do
          expect(hash_klass.new(validated_key: ["0.0", 5.0, 9]).validated_key).to eq([0.0, 5.0, 9.0])
        end
      end

      context "for more complex data types" do
        let(:hash_klass) do
          stub_const("CastClass", Class.new(Object))
          CastClass.class_eval do
            attr_accessor :member
            def initialize(m)
              @member = m
            end
          end

          stub_const("SimpleStructishChild", Class.new(Structish::Hash))
          SimpleStructishChild.class_eval do
            validate :validated_key, ::Array, of: CastClass, cast: true
          end
          SimpleStructishChild
        end

        it "casts each element of the array" do
          expect(hash_klass.new(validated_key: ["0.0", 5.0, 9]).validated_key.map(&:class)).to eq([CastClass, CastClass, CastClass])
        end
      end
    end
  end

  describe "custom data types" do
    describe "Any" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, Structish::Any
        end
        SimpleStructishChild
      end

      it "allows any data type" do
        expect(hash_klass.new(validated_key: 0.0).validated_key).to eq(0.0)
        expect(hash_klass.new(validated_key: "hello").validated_key).to eq("hello")
        expect(hash_klass.new(validated_key: ["hello"]).validated_key).to eq(["hello"])
        expect(hash_klass.new(validated_key: {key: "value"}).validated_key).to eq({key: "value"})
      end
    end

    describe "Boolean" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, Structish::Boolean
        end
        SimpleStructishChild
      end

      it "allows TrueClass and FalseClass data types" do
        expect(hash_klass.new(validated_key: true).validated_key).to eq(true)
        expect(hash_klass.new(validated_key: false).validated_key).to eq(false)
        expect { hash_klass.new(validated_key: 0.0) }.to raise_error("Class mismatch for validated_key -> Float. Should be a TrueClass, FalseClass")
      end
    end

    describe "Number" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, Structish::Number
        end
        SimpleStructishChild
      end

      it "allows float and integer data types" do
        expect(hash_klass.new(validated_key: 0.0).validated_key).to eq(0.0)
        expect(hash_klass.new(validated_key: 1).validated_key).to eq(1)
        expect { hash_klass.new(validated_key: "hello") }.to raise_error("Class mismatch for validated_key -> String. Should be a Integer, Float")
      end
    end

    describe "Primitive" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, Structish::Primitive
        end
        SimpleStructishChild
      end

      it "allows primitive data types" do
        expect(hash_klass.new(validated_key: 0.0).validated_key).to eq(0.0)
        expect(hash_klass.new(validated_key: 1).validated_key).to eq(1)
        expect(hash_klass.new(validated_key: false).validated_key).to eq(false)
        expect(hash_klass.new(validated_key: true).validated_key).to eq(true)
        expect(hash_klass.new(validated_key: "hello").validated_key).to eq("hello")
        expect(hash_klass.new(validated_key: :hello).validated_key).to eq(:hello)
        expect { hash_klass.new(validated_key: {}) }.to raise_error("Class mismatch for validated_key -> Hash. Should be a String, Float, Integer, TrueClass, FalseClass, Symbol")
      end
    end
  end

  describe "custom validations" do
    let(:hash_klass) do
      stub_const("PositiveValidation", Class.new(Structish::Validation))
      PositiveValidation.class_eval do
        def validate
          value > 0
        end
      end

      stub_const("SimpleStructishChild", Class.new(Structish::Hash))
      SimpleStructishChild.class_eval do
        validate :validated_key, Structish::Number, validation: PositiveValidation
      end
      SimpleStructishChild
    end

    context "when the value satisifies the validation" do
      it "raises an appropriate error" do
        expect { hash_klass.new(validated_key: -1) }.to raise_error(Structish::ValidationError, "Custom validation PositiveValidation not met")
      end
    end

    context "when the value does not satisfy the validation" do
      it "creates the object" do
        expect(hash_klass.new(validated_key: 1).validated_key).to eq(1)
      end
    end

    context "when other entries in the constructor are needed for validation" do
      let(:hash_klass) do
        stub_const("LessThanLargestValidation", Class.new(Structish::Validation))
        LessThanLargestValidation.class_eval do
          def validate
            value < constructor[:largest]
          end
        end

        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :smallest, Structish::Number, validation: LessThanLargestValidation
          validate :largest, Structish::Number
        end
        SimpleStructishChild
      end

      it "passes the constructor into the validation instance" do
        expect(hash_klass.new(largest: 10, smallest: 5).smallest).to eq(5)
        expect { hash_klass.new(largest: 10, smallest: 20) }.to raise_error(Structish::ValidationError, "Custom validation LessThanLargestValidation not met")
      end
    end
  end

  describe ".validate_all" do
    let(:hash_klass) do
      stub_const("SimpleStructishChild", Class.new(Structish::Hash))
      SimpleStructishChild.class_eval do
        validate_all Structish::Number
      end
      SimpleStructishChild
    end

    let(:instance) { hash_klass.new(hash) }

    context "when all the values match the conditions" do
      let(:hash) { {one: 1.0, two: 2} }

      it "creates the object" do
        expect(instance[:one]).to eq(1.0)
        expect(instance[:two]).to eq(2)
      end
    end

    context "when not all the values match the conditions" do
      let(:hash) { {one: 1.0, two: "two"} }

      it "raises an appropriate error" do
        expect { instance }.to raise_error(Structish::ValidationError, "Class mismatch for two -> String. Should be a Integer, Float")
      end
    end
  end

  describe "#initialize" do
    context "when a non-hash is passed to the constructor" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key
        end
        SimpleStructishChild
      end

      it "raises an appropriate error" do
        expect { hash_klass.new(1) }.to raise_error(ArgumentError, "Only hash-like objects can be used as constructors for Structish::Hash")
      end
    end

    context "when validating presence" do
      context "when the value is nil" do
        let(:hash) { {validated_key: nil, non_validated_key: "Not a validated key"} }

        it "raises an appropriate validation error" do
          expect { hash_object }.to raise_error(Structish::ValidationError, "Required value validated_key not present")
        end
      end

      context "when the value is blank but not nil" do
        let(:hash) { {validated_key: "", non_validated_key: "Not a validated key"} }

        it "creates the object" do
          expect { hash_object }.not_to raise_error
          expect(hash_object.validated_key).to eq("")
        end
      end
    end

    context "when 'of' is specified for an array class" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, ::Array, of: String
        end
        SimpleStructishChild
      end

      context "when the value is not an array" do
        let(:hash) { {validated_key: "hello"} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structish::ValidationError, "Class mismatch for validated_key. All values should be of type String")
        end
      end

      context "when some objects in the array are not of the appropriate type" do
        let(:hash) { {validated_key: ["hello", 0.0]} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structish::ValidationError, "Class mismatch for validated_key. All values should be of type String")
        end
      end

      context "when all objects in the array are of the specified type" do
        let(:hash) { {validated_key: ["hello", "world"]} }

        it "creates the object" do
          expect(hash_object.validated_key).to eq(["hello", "world"])
        end
      end
    end

    context "when 'of' is specified for a hash class" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, ::Hash, of: String
        end
        SimpleStructishChild
      end

      context "when the value is not a hash" do
        let(:hash) { {validated_key: "hello"} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structish::ValidationError, "Class mismatch for validated_key. All values should be of type String")
        end
      end

      context "when some objects in the hash are not of the appropriate type" do
        let(:hash) { {validated_key: {0 => "First", 1 => 1.0}} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structish::ValidationError, "Class mismatch for validated_key. All values should be of type String")
        end
      end

      context "when all objects in the hash are of the specified type" do
        let(:hash) { {validated_key: {0 => "First", 1 => "Second"}} }

        it "creates the object" do
          expect(hash_object.validated_key).to eq({0 => "First", 1 => "Second"})
        end
      end
    end

    context "when validating class type" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key, ::Hash
        end
        SimpleStructishChild
      end

      context "when the value class is not a child of the specified class" do
        it "raises an appropriate validation error" do
          expect { hash_klass.new(validated_key: "hello") }.to raise_error(Structish::ValidationError, "Class mismatch for validated_key -> String. Should be a Hash")
        end
      end

      context "when the value class is equal to the specified class" do
        it "creates the object" do
          expect(hash_klass.new(validated_key: {zero: 0.0}).validated_key).to eq({zero: 0.0})
        end
      end

      context "when the value class is a child of the specified class" do
        let(:dummy_child_class) { stub_const("DummyFloatChild", Class.new(::Hash)); DummyFloatChild }

        it "creates the object" do
          expect(hash_klass.new(validated_key: dummy_child_class.new({zero: 0.0})).validated_key).to eq(dummy_child_class.new({zero: 0.0}))
        end
      end

      context "when an array of classes is specified" do
        let(:hash_klass) do
          stub_const("SimpleStructishChild", Class.new(Structish::Hash))
          SimpleStructishChild.class_eval do
            validate :validated_key, [String, Float]
          end
          SimpleStructishChild
        end

        context "when the value class matches one of the classes" do
          it "creates the object" do
            expect(hash_klass.new(validated_key: 0.0).validated_key).to eq(0.0)
            expect(hash_klass.new(validated_key: "hello").validated_key).to eq("hello")
          end
        end

        context "when the value class does not match one of the classes" do
          it "raises an appropriate validation error" do
            expect { hash_klass.new(validated_key: :hello) }.to raise_error(Structish::ValidationError, "Class mismatch for validated_key -> Symbol. Should be a String, Float")
          end
        end
      end

      context "when symbolize is flagged as true" do
        let(:hash_klass) do
          stub_const("SimpleStructishChild", Class.new(Structish::Hash))
          SimpleStructishChild.class_eval do
            validate :validated_key

            symbolize true
          end
          SimpleStructishChild
        end

        let(:hash) { {"validated_key" => 0} }

        it "symbolizes the keys" do
          expect(hash_klass.new(hash).to_h).to eq(hash.symbolize_keys)
          expect(hash_klass.new(hash)[:validated_key]).to eq(0)
        end
      end
    end
  end
end
