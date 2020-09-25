require "spec_helper"

describe Structish::Validation do
  describe "#validate" do
    context "when the method is not overridden" do
      it "raises an error" do
        expect { Structish::Validation.new(1, {}).validate }.to raise_error(NotImplementedError, "Validation conditions function must be defined")
      end
    end
  end
end
