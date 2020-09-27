require "spec_helper"

describe ::Hash do
  describe "#with_indifferent_numerical_access" do
    it "returns a HashWithIndifferentNumericalAccess object with the same data" do
      expect({foo: "bar"}.with_indifferent_numerical_access).to be_a(HashWithIndifferentNumericalAccess)
      expect({foo: "bar"}.with_indifferent_numerical_access.to_h).to eq({foo: "bar"})
    end
  end

  describe "#to_structish" do
    context "when the class is a valid structish class" do
      let(:hash_klass) do
        stub_const("SimpleStructishChild", Class.new(Structish::Hash))
        SimpleStructishChild.class_eval do
          validate :validated_key
        end
        SimpleStructishChild
      end

      let(:result) { {validated_key: 0.0}.to_structish(hash_klass) }

      it "creates an instance of the structish class" do
        expect(result).to be_a(SimpleStructishChild)
        expect(result.to_h).to eq({validated_key: 0.0})
      end
    end

    context "when the class is not a valida structish class" do
      let(:result) { {validated_key: 0.0}.to_structish(::Hash) }

      it "raises an error" do
        expect { result }.to raise_error("Class is not a child of Structish::Hash")
      end
    end
  end
end

describe ::Array do
  describe "#pluck" do
    it "pulls the values out from an array of hashes" do
      expect([{key: "value_1"}, {key: "value_2"}].pluck(:key)).to eq(["value_1", "value_2"])
    end
  end

  describe "#to_structish" do
    context "when the class is a valid structish class" do
      let(:array_klass) do
        stub_const("SimpleStructishArray", Class.new(Structish::Array))
        SimpleStructishArray.class_eval do
          validate_all Structish::Number
        end
        SimpleStructishArray
      end

      let(:result) { [0, 0.0, 5].to_structish(array_klass) }

      it "creates an instance of the structish class" do
        expect(result).to be_a(SimpleStructishArray)
        expect(result.to_a).to eq([0, 0.0, 5])
      end
    end

    context "when the class is not a valida structish class" do
      let(:result) { [0, 0.0, 5].to_structish(::Array) }

      it "raises an error" do
        expect { result }.to raise_error("Class is not a child of Structish::Array")
      end
    end
  end

  describe "#values" do
    context "for empty arrays" do
      it "returns an empty array" do
        expect([].values).to eq([])
      end
    end

    context "for non-empty arrays" do
      it "returns the values of the array" do
        expect([5, "foo", {}, 6425].values).to eq([5, "foo", {}, 6425])
      end
    end

    context "for objects that inherit from ::Array" do
      let(:array_klass) do
        stub_const("ArrayChildKlass", Class.new(::Array))
        ArrayChildKlass
      end

      let(:object) { array_klass.new([5, "foo", {}, 6425]) }

      it "returns the array" do
        expect(object.values).to be_a(Array)
        expect(object.values).to match(object.to_a)
      end
    end
  end

  describe "#keys" do
    context "for empty arrays" do
      it "returns an empty array" do
        expect([].keys).to eq([])
      end
    end

    context "for non-empty arrays" do
      it "returns an array of the possible integer accessors into the array" do
        expect([5, "foo", {}, 6425].keys).to eq([0, 1, 2, 3])
      end
    end
  end
end

describe ::Object do
  describe "#floaty?" do
    context "when the object can be cast into a float" do
      it "returns true" do
        expect("0.0".floaty?).to eq(true)
        expect(0.0.floaty?).to eq(true)
        expect("0".floaty?).to eq(true)
        expect(0.floaty?).to eq(true)
      end
    end

    context "when the object cannot be cast into a float" do
      it "returns false" do
        expect("foo".floaty?).to eq(false)
        expect({}.floaty?).to eq(false)
      end
    end
  end

  describe "#inty?" do
    context "when the object can be cast into an int" do
      it "returns true" do
        expect("0".inty?).to eq(true)
        expect(0.inty?).to eq(true)
        expect(0.0.inty?).to eq(true)
      end
    end

    context "when the object cannot be cast into an int" do
      it "returns false" do
        expect("0.0".inty?).to eq(false)
        expect("foo".inty?).to eq(false)
        expect({}.inty?).to eq(false)
      end
    end
  end

  describe "#numerical?" do
    context "when the object can be cast into either an integer or a float" do
      it "returns true" do
        expect("0.0".numerical?).to eq(true)
        expect(0.0.numerical?).to eq(true)
        expect("0".numerical?).to eq(true)
        expect(0.numerical?).to eq(true)
      end
    end

    context "when the object can be cast into neither an integer nor a float" do
      it "returns false" do
        expect("foo".numerical?).to eq(false)
        expect({}.numerical?).to eq(false)
      end
    end
  end

  describe "#num_eq?" do
    context "when both objects are numerical" do
      it "returns true" do
        expect(0.num_eq?(0.0)).to eq(true)
        expect(0.num_eq?("0.0")).to eq(true)
        expect("0".num_eq?("0.0")).to eq(true)
        expect("0".num_eq?(0.0)).to eq(true)
        expect(0.0.num_eq?(0.0)).to eq(true)
      end
    end

    context "when one object is not numerical" do
      it "returns false" do
        expect(0.num_eq?("foo")).to eq(false)
      end
    end

    context "when neither object is numerical and the objects are not equal" do
      it "returns false" do
        expect({}.num_eq?("bar")).to eq(false)
      end
    end

    context "when neither object is numerical and the objects are equal" do
      it "returns true" do
        expect({}.num_eq?({})).to eq(true)
      end
    end
  end
end
