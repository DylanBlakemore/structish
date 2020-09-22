require "spec_helper"

describe ::Array do
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
