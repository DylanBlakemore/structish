require "spec_helper"

describe Structable::Hash do

  let(:hash_klass) do
    stub_const("SimpleStructableChild", Class.new(Structable::Hash))
    SimpleStructableChild.class_eval do
      validate :validated_key
    end
    SimpleStructableChild
  end
  let(:hash_object) { hash_klass.new(hash) }
  let(:hash) { {} }

  describe "#dynamic accessor methods" do
    let(:hash) { {validated_key: "A validated key", non_validated_key: "Not a validated key"} }

    it "create a method for the validated key" do
      expect(hash_object[:validated_key]).to eq("A validated key")
      expect(hash_object.validated_key).to eq("A validated key")
      expect(hash_object[:non_validated_key]).to eq("Not a validated key")
      expect { hash_object.non_validated_key }.to raise_error(NoMethodError)
    end
  end

  describe "custom data types" do
    describe "Any" do
      let(:hash_klass) do
        stub_const("SimpleStructableChild", Class.new(Structable::Hash))
        SimpleStructableChild.class_eval do
          validate :validated_key, Structable::Any
        end
        SimpleStructableChild
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
        stub_const("SimpleStructableChild", Class.new(Structable::Hash))
        SimpleStructableChild.class_eval do
          validate :validated_key, Structable::Boolean
        end
        SimpleStructableChild
      end

      it "allows TrueClass and FalseClass data types" do
        expect(hash_klass.new(validated_key: true).validated_key).to eq(true)
        expect(hash_klass.new(validated_key: false).validated_key).to eq(false)
        expect { hash_klass.new(validated_key: 0.0) }.to raise_error("Class mismatch for validated_key -> Float. Should be a TrueClass, FalseClass")
      end
    end

    describe "Number" do
      let(:hash_klass) do
        stub_const("SimpleStructableChild", Class.new(Structable::Hash))
        SimpleStructableChild.class_eval do
          validate :validated_key, Structable::Number
        end
        SimpleStructableChild
      end

      it "allows TrueClass and FalseClass data types" do
        expect(hash_klass.new(validated_key: 0.0).validated_key).to eq(0.0)
        expect(hash_klass.new(validated_key: 1).validated_key).to eq(1)
        expect { hash_klass.new(validated_key: "hello") }.to raise_error("Class mismatch for validated_key -> String. Should be a Integer, Float")
      end
    end
  end

  describe "custom validations" do
    let(:hash_klass) do
      stub_const("PositiveValidation", Class.new(Structable::Validation))
      PositiveValidation.class_eval do
        def validate
          value > 0
        end
      end

      stub_const("SimpleStructableChild", Class.new(Structable::Hash))
      SimpleStructableChild.class_eval do
        validate :validated_key, Structable::Number, validation: PositiveValidation
      end
      SimpleStructableChild
    end

    context "when the value satisifies the validation" do
      it "raises an appropriate error" do
        expect { hash_klass.new(validated_key: -1) }.to raise_error(Structable::ValidationError, "Custom validation PositiveValidation not met")
      end
    end

    context "when the value does not satisfy the validation" do
      it "creates the object" do
        expect(hash_klass.new(validated_key: 1).validated_key).to eq(1)
      end
    end
  end

  describe ".validate_all" do
    let(:hash_klass) do
      stub_const("SimpleStructableChild", Class.new(Structable::Hash))
      SimpleStructableChild.class_eval do
        validate_all Structable::Number
      end
      SimpleStructableChild
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
        expect { instance }.to raise_error(Structable::ValidationError, "Class mismatch for two -> String. Should be a Integer, Float")
      end
    end
  end

  describe "#initialize" do
    context "when validating presence" do
      context "when the value is nil" do
        let(:hash) { {validated_key: nil, non_validated_key: "Not a validated key"} }

        it "raises an appropriate validation error" do
          expect { hash_object }.to raise_error(Structable::ValidationError, "Required value validated_key not present")
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
        stub_const("SimpleStructableChild", Class.new(Structable::Hash))
        SimpleStructableChild.class_eval do
          validate :validated_key, ::Array, of: String
        end
        SimpleStructableChild
      end

      context "when the value is not an array" do
        let(:hash) { {validated_key: "hello"} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structable::ValidationError, "Class mismatch for validated_key. All values should be of type String")
        end
      end

      context "when some objects in the array are not of the appropriate type" do
        let(:hash) { {validated_key: ["hello", 0.0]} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structable::ValidationError, "Class mismatch for validated_key. All values should be of type String")
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
        stub_const("SimpleStructableChild", Class.new(Structable::Hash))
        SimpleStructableChild.class_eval do
          validate :validated_key, ::Hash, of: String
        end
        SimpleStructableChild
      end

      context "when the value is not an array" do
        let(:hash) { {validated_key: "hello"} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structable::ValidationError, "Class mismatch for validated_key. All values should be of type String")
        end
      end

      context "when some objects in the array are not of the appropriate type" do
        let(:hash) { {validated_key: {0 => "First", 1 => 1.0}} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structable::ValidationError, "Class mismatch for validated_key. All values should be of type String")
        end
      end

      context "when all objects in the array are of the specified type" do
        let(:hash) { {validated_key: {0 => "First", 1 => "Second"}} }

        it "creates the object" do
          expect(hash_object.validated_key).to eq({0 => "First", 1 => "Second"})
        end
      end
    end

    context "when validating class type" do
      let(:hash_klass) do
        stub_const("SimpleStructableChild", Class.new(Structable::Hash))
        SimpleStructableChild.class_eval do
          validate :validated_key, ::Hash
        end
        SimpleStructableChild
      end

      context "when the value class is not a child of the specified class" do
        it "raises an appropriate validation error" do
          expect { hash_klass.new(validated_key: "hello") }.to raise_error(Structable::ValidationError, "Class mismatch for validated_key -> String. Should be a Hash")
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
          stub_const("SimpleStructableChild", Class.new(Structable::Hash))
          SimpleStructableChild.class_eval do
            validate :validated_key, [String, Float]
          end
          SimpleStructableChild
        end

        context "when the value class matches one of the classes" do
          it "creates the object" do
            expect(hash_klass.new(validated_key: 0.0).validated_key).to eq(0.0)
            expect(hash_klass.new(validated_key: "hello").validated_key).to eq("hello")
          end
        end

        context "when the value class does not match one of the classes" do
          it "raises an appropriate validation error" do
            expect { hash_klass.new(validated_key: :hello) }.to raise_error(Structable::ValidationError, "Class mismatch for validated_key -> Symbol. Should be a String, Float")
          end
        end
      end

      context "when symbolize is flagged as true" do
        let(:hash_klass) do
          stub_const("SimpleStructableChild", Class.new(Structable::Hash))
          SimpleStructableChild.class_eval do
            validate :validated_key

            symbolize true
          end
          SimpleStructableChild
        end

        let(:hash) { {"validated_key" => 0} }

        it "symbolizes the keys" do
          expect(hash_klass.new(hash).to_h).to eq(hash.symbolize_keys)
          expect(hash_klass.new(hash)[:validated_key]).to eq(0)
        end
      end

      context "when the strict option is flagged" do
        context "when the value class is a child class" do
          it "raises an appropriate validation error" do

          end
        end

        context "when the value class is an exact match" do
          it "creates the object" do

          end
        end
      end
    end
  end
end
