# frozen_string_literal: true

require "spec_helper"

describe RubyPgExtras::SizeParser do
  subject(:result) { described_class.to_i(arg) }

  describe "SI Units" do
    let(:arg) { "#{num_units} #{unit}" }

    context "when the argument is a number followed by 'bytes', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[bytes BYTES Bytes].sample }

      it { is_expected.to eq(num_units) }
    end

    context "when the argument is a number followed by 'kB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[kB kb KB].sample }

      it { is_expected.to eq(num_units * 1000) }
    end

    context "when the argument is a number followed by 'MB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[MB Mb mb].sample }

      it { is_expected.to eq(num_units * 1000 * 1000) }
    end

    context "when the argument is a number followed by 'GB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[GB Gb gb].sample }

      it { is_expected.to eq(num_units * 1000 * 1000 * 1000) }
    end

    context "when the argument is a number followed by 'TB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[TB Tb tb].sample }

      it { is_expected.to eq(num_units * 1000 * 1000 * 1000 * 1000) }
    end

    context "when the argument is a number followed by 'PB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[PB Pb pb].sample }

      it { is_expected.to eq(num_units * 1000 * 1000 * 1000 * 1000 * 1000) }
    end

    context "when the argument is a number followed by 'EB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[EB Eb eb].sample }

      it { is_expected.to eq(num_units * 1000 * 1000 * 1000 * 1000 * 1000 * 1000) }
    end

    context "when the argument is a number followed by 'ZB', with possible case variations" do
      let(:num_units) { 912 }
      let(:unit) { %w[ZB Zb zb].sample }

      it { is_expected.to eq(num_units * 1000 * 1000 * 1000 * 1000 * 1000 * 1000 * 1000) }
    end

    context "when the argument is a number followed by 'YB', with possible case variations" do
      let(:num_units) { 912 }
      let(:unit) { %w[YB Yb yb].sample }

      it { is_expected.to eq(num_units * 1000 * 1000 * 1000 * 1000 * 1000 * 1000 * 1000 * 1000) }
    end
  end

  describe "Binary Units" do
    let(:arg) { "#{num_units} #{unit}" }

    context "when the argument is a number followed by 'bytes', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[bytes BYTES Bytes].sample }

      it { is_expected.to eq(num_units) }
    end

    context "when the argument is a number followed by 'kiB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[kiB kib KiB].sample }

      it { is_expected.to eq(num_units * 1024) }
    end

    context "when the argument is a number followed by 'MiB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[MiB Mib mib].sample }

      it { is_expected.to eq(num_units * 1024 * 1024) }
    end

    context "when the argument is a number followed by 'GiB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[GiB Gib gib].sample }

      it { is_expected.to eq(num_units * 1024 * 1024 * 1024) }
    end

    context "when the argument is a number followed by 'TiB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[TiB Tib tib].sample }

      it { is_expected.to eq(num_units * 1024 * 1024 * 1024 * 1024) }
    end

    context "when the argument is a number followed by 'PiB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[PiB Pib pib].sample }

      it { is_expected.to eq(num_units * 1024 * 1024 * 1024 * 1024 * 1024) }
    end

    context "when the argument is a number followed by 'EiB', with possible case variations" do
      let(:num_units) { rand(1000) }
      let(:unit) { %w[EiB Eib eib].sample }

      it { is_expected.to eq(num_units * 1024 * 1024 * 1024 * 1024 * 1024 * 1024) }
    end

    context "when the argument is a number followed by 'ZB', with possible case variations" do
      let(:num_units) { 912 }
      let(:unit) { %w[ZiB Zib zib].sample }

      it { is_expected.to eq(num_units * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024) }
    end

    context "when the argument is a number followed by 'YB', with possible case variations" do
      let(:num_units) { 912 }
      let(:unit) { %w[YiB Yib yib].sample }

      it { is_expected.to eq(num_units * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024) }
    end
  end

  context "when the argument has only digits" do
    let(:arg) { "654245" }

    it { is_expected.to eq(arg.to_i) }
  end

  describe "errors" do
    it "raises an error when the argument has an invalid prefix" do
      expect do
        described_class.to_i("123 qb")
      end.to raise_error ArgumentError
    end

    it "raises an error when the argument does not have a unit in bytes" do
      expect do
        described_class.to_i("123 mL")
      end.to raise_error ArgumentError
    end

    it "when the argument cannot be parsed an number of units" do
      expect do
        described_class.to_i("1c3 MB")
      end.to raise_error ArgumentError
    end
  end
end
