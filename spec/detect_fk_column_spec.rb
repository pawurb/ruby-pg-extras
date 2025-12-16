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

    context "matching table with underscored prefix" do
      let(:column_name) { "account_user_id" }
      let(:tables) { ["account_users", "users"] }

      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "matching table with uncountable noun" do
      let(:column_name) { "fish_id" }
      let(:tables) { ["fish", "users"] }

      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "matching table with mixed-case column name" do
      let(:column_name) { "User_id" }
      let(:tables) { ["users", "posts"] }

      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "matching table with irregular plural already pluralized" do
      let(:column_name) { "people_id" }
      let(:tables) { ["people", "users"] }

      it "returns true" do
        expect(result).to eq(true)
      end
    end
  end
end
