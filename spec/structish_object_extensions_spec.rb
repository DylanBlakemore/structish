require "spec_helper"

describe ::Hash do
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

    context "when the class is not a valid structish class" do
      let(:result) { {validated_key: 0.0}.to_structish(::Hash) }

      it "raises an error" do
        expect { result }.to raise_error("Class is not a child of Structish::Hash")
      end
    end
  end
end

describe ::Array do
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
