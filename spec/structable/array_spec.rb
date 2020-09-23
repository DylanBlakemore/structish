require "spec_helper"

describe Structish::Array do
  describe ".validate_all" do
    let(:array_klass) do
      stub_const("SimpleStructishArray", Class.new(Structish::Array))
      SimpleStructishArray.class_eval do
        validate_all Structish::Number
      end
      SimpleStructishArray
    end

    context "when all entries pass validation" do
      it "creates the object" do
        expect(array_klass.new([0.0, 1.0, 2.0]).to_a).to eq([0.0, 1.0, 2.0])
      end
    end

    context "when all the entries do not pass validation" do
      it "raises an appropriate error" do
        expect { array_klass.new([0.0, "1.0"]) }.to raise_error(Structish::ValidationError, "Class mismatch for 1 -> String. Should be a Integer, Float")
      end
    end
  end

  describe ".validate" do
    describe "optional entries" do
      let(:array_klass) do
        stub_const("SimpleStructishArray", Class.new(Structish::Array))
        SimpleStructishArray.class_eval do
          validate 0, Structish::Number
          validate 1, String, optional: true
        end
        SimpleStructishArray
      end

      context "when an argument is optional and does not exist" do
        it "creates the object" do
          expect(array_klass.new([15]).first).to eq(15)
        end
      end
    end

    describe "class validation" do
      let(:array_klass) do
        stub_const("SimpleStructishArray", Class.new(Structish::Array))
        SimpleStructishArray.class_eval do
          validate 0, Structish::Number
          validate 1, String
        end
        SimpleStructishArray
      end

      let(:instance) { array_klass.new(array) }

      context "when the entries all pass validation" do
        let(:array) { [0.0, "hello"]}

        it "creates the object" do
          expect(instance[0]).to eq(0.0)
          expect(instance[1]).to eq("hello")
        end
      end

      context "when the entries do not pass validation" do
        let(:array) { [0.0, 1.0]}

        it "raises an appropriate error" do
          expect { instance }.to raise_error(Structish::ValidationError, "Class mismatch for 1 -> Float. Should be a String")
        end
      end
    end
  end
end
