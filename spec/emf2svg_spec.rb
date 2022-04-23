# frozen_string_literal: true

RSpec.describe Emf2svg do
  it "has a version number" do
    expect(Emf2svg::VERSION).not_to be nil
  end

  let(:example_file) { File.expand_path("examples/image1.emf", __dir__) }

  it "converts from file unscaled" do
    expect(described_class.from_file(example_file).size).to eq 39849
  end

  it "converts from string unscaled" do
    string = File.read(example_file, mode: "rb")
    expect(described_class.from_binary_string(string).size).to eq 39849
  end

  it "converts from file scaled" do
    converted = described_class.from_file(example_file, 800, 600)
    expect(converted.size).to eq 39607
  end

  it "converts from string scaled" do
    string = File.read(example_file, mode: "rb")
    converted = described_class.from_binary_string(string, 800, 600)
    expect(converted.size).to eq 39607
  end
end
