# frozen_string_literal: true

require "spec_helper"
require "ruby-pg-extras"

describe RubyPgExtras::IgnoreList do
  describe "#ignored?" do
    it "returns false when ignore_list is nil" do
      list = described_class.new(nil)
      expect(list.ignored?(table: "posts", column_name: "topic_id")).to eq(false)
    end

    it "supports '*' to ignore everything" do
      list = described_class.new(["*"])
      expect(list.ignored?(table: "posts", column_name: "topic_id")).to eq(true)
      expect(list.ignored?(table: "users", column_name: "customer_id")).to eq(true)
    end

    it "supports 'table.*' to ignore all columns for a table" do
      list = described_class.new(["posts.*"])
      expect(list.ignored?(table: "posts", column_name: "topic_id")).to eq(true)
      expect(list.ignored?(table: "posts", column_name: "user_id")).to eq(true)
      expect(list.ignored?(table: "users", column_name: "topic_id")).to eq(false)
    end

    it "supports 'column' to ignore a column name globally" do
      list = described_class.new(["topic_id"])
      expect(list.ignored?(table: "posts", column_name: "topic_id")).to eq(true)
      expect(list.ignored?(table: "users", column_name: "topic_id")).to eq(true)
      expect(list.ignored?(table: "posts", column_name: "user_id")).to eq(false)
    end

    it "supports 'table.column' to ignore a specific table+column" do
      list = described_class.new(["posts.topic_id"])
      expect(list.ignored?(table: "posts", column_name: "topic_id")).to eq(true)
      expect(list.ignored?(table: "users", column_name: "topic_id")).to eq(false)
      expect(list.ignored?(table: "posts", column_name: "user_id")).to eq(false)
    end

    it "accepts ignore_list as a comma-separated string" do
      list = described_class.new("posts.topic_id, customer_id")
      expect(list.ignored?(table: "posts", column_name: "topic_id")).to eq(true)
      expect(list.ignored?(table: "users", column_name: "customer_id")).to eq(true)
      expect(list.ignored?(table: "users", column_name: "topic_id")).to eq(false)
    end

    it "strips whitespace, drops empty entries and de-duplicates" do
      list = described_class.new([" posts.topic_id ", "", "posts.topic_id", "  "])
      expect(list.ignored?(table: "posts", column_name: "topic_id")).to eq(true)
      expect(list.ignored?(table: "users", column_name: "topic_id")).to eq(false)
    end

    it "raises ArgumentError for unsupported ignore_list types" do
      expect { described_class.new(123) }.to raise_error(ArgumentError)
      expect { described_class.new({}) }.to raise_error(ArgumentError)
    end
  end
end


