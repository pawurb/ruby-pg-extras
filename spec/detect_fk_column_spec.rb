# frozen_string_literal: true

require "spec_helper"

describe RubyPgExtras::DetectFkColumn do
  subject(:result) do
    RubyPgExtras::DetectFkColumn.call(column_name, tables)
  end

  describe "call" do
    context "no matching table" do
      let(:column_name) { "company_id" }
      let(:tables) { ["users", "posts"] }

      it "returns false" do
        expect(result).to eq(false)
      end
    end

    context "matching table" do
      let(:column_name) { "user_id" }
      let(:tables) { ["users", "posts"] }

      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "matching table" do
      let(:column_name) { "octopus_id" }
      let(:tables) { ["users", "octopi"] }

      it "returns true" do
        expect(result).to eq(true)
      end
    end
  end
end
