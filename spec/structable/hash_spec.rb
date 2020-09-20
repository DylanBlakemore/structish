require 'spec_helper'

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
          validate :validated_key, Array, of: String
        end
        SimpleStructableChild
      end

      context "when the value is not an array" do
        let(:hash) { {validated_key: "hello"} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structable::ValidationError, "Class mismatch for validated_key. Should be an array with all String elements.")
        end
      end

      context "when some objects in the array are not of the appropriate type" do
        let(:hash) { {validated_key: ["hello", 0.0]} }

        it "raises an appropriate error" do
          expect { hash_object }.to raise_error(Structable::ValidationError, "Class mismatch for validated_key. Should be an array with all String elements.")
        end
      end

      context "when all objects in the array are of the specified type" do
        let(:hash) { {validated_key: ["hello", "world"]} }

        it "creates the object" do
          expect(hash_object.validated_key).to eq(["hello", "world"])
        end
      end

    end

    context "when validating class type" do
      context "when the value class is not a child of the specified class" do
        it "raises an appropriate validation error" do

        end
      end

      context "when the value class is equal to the specified class" do
        it "creates the object" do

        end
      end

      context "when the value class is a child of the specified class" do
        it "creates the object" do

        end
      end

      context "when an array of classes is specified" do
        context "when the value class matches one of the classes" do
          it "creates the object" do

          end
        end

        context "when the value class does not match one of the classes" do
          it "raises an appropriate validation error" do

          end
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
