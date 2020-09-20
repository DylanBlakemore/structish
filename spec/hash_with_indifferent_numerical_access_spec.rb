require "spec_helper"

describe ::Hash do
  describe "#with_indifferent_numerical_access" do
    it "returns a HashWothIndifferentNumericalAccess" do
      expect({"0.0" => "Zero"}.with_indifferent_numerical_access).to be_a(HashWithIndifferentNumericalAccess)
    end
  end
end

describe HashWithIndifferentNumericalAccess do
  describe "#[]" do
    context "when the hash key is a float" do
      let(:hash) do
        {
          0.0 => "One",
          1.0 => "Two"
        }.with_indifferent_numerical_access
      end

      it "returns the result regardless of data type" do
        expect(hash[0.0]).to eq "One"
        expect(hash[0]).to eq "One"
        expect(hash["0.0"]).to eq "One"
      end
    end

    context "when the hash key is an int" do
      let(:hash) do
        {
          0 => "One",
          1 => "Two"
        }.with_indifferent_numerical_access
      end

      it "returns the result regardless of data type" do
        expect(hash[0.0]).to eq "One"
        expect(hash[0]).to eq "One"
        expect(hash["0.0"]).to eq "One"
      end
    end

    context "when the hash key is a stringified float" do
      let(:hash) do
        {
          "0.0" => "One",
          "1.0" => "Two"
        }.with_indifferent_numerical_access
      end

      it "returns the result regardless of data type" do
        expect(hash[0.0]).to eq "One"
        expect(hash[0]).to eq "One"
        expect(hash["0.0"]).to eq "One"
      end
    end

    context "when the hash key is a stringified int" do
      let(:hash) do
        {
          "0" => "One",
          "1" => "Two"
        }.with_indifferent_numerical_access
      end

      it "returns the result regardless of data type" do
        expect(hash[0.0]).to eq "One"
        expect(hash[0]).to eq "One"
        expect(hash["0.0"]).to eq "One"
      end
    end

    context "when the key cannot be parsed into a number" do
      let(:hash) do
        {
          "0" => "One",
          "1" => "Two",
          "a_key" => "A key value"
        }.with_indifferent_numerical_access
      end

      it "returns nil" do
        expect(hash["a_key"]).to eq("A key value")
        expect(hash["not_a_key"]).to be_nil
      end
    end

    context "for nested hashes" do
      let(:hash) do
        {
          "0.0" => {
            1.0 => {
              1 => "Hello"
            }
          }
        }.with_indifferent_numerical_access
      end

      it "uses indifferent numerical access for sub-hashes" do
        expect(hash[0]["1"][1.0]).to eq("Hello")
      end
    end
  end
end
