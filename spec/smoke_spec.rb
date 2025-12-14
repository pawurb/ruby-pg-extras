# frozen_string_literal: true

require "spec_helper"

describe RubyPgExtras do
  RubyPgExtras::QUERIES.each do |query_name|
    it "#{query_name} description can be read" do
      expect do
        RubyPgExtras.description_for(
          query_name: query_name,
        )
      end.not_to raise_error
    end
  end

  SKIP_QUERIES = %i[
    kill_all
    table_schema
    table_foreign_keys
  ]

  RubyPgExtras::QUERIES.reject { |q| SKIP_QUERIES.include?(q) }.each do |query_name|
    it "#{query_name} query can be executed" do
      expect do
        RubyPgExtras.run_query(
          query_name: query_name,
          in_format: :hash,
        )
      end.not_to raise_error
    end
  end

  describe "table_foreign_keys" do
    it "returns a correct fk info" do
      result = RubyPgExtras.table_foreign_keys(args: { table_name: :posts }, in_format: :hash)
      expect(result.size).to eq(2)
      expect(result[0].keys).to eq(["table_name", "constraint_name", "column_name", "foreign_table_name", "foreign_column_name"])
    end

    it "requires table_name arg" do
      expect {
        RubyPgExtras.table_foreign_keys(in_format: :hash)
      }.to raise_error(ArgumentError)
    end
  end

  describe "table_schema" do
    it "returns a correct schema" do
      result = RubyPgExtras.table_schema(args: { table_name: :users }, in_format: :hash)
      expect(result.size).to eq(4)
      expect(result[0].keys).to eq(["column_name", "data_type", "is_nullable", "column_default"])
    end

    it "requires table_name arg" do
      expect {
        RubyPgExtras.table_schema(in_format: :hash)
      }.to raise_error(ArgumentError)
    end
  end

  describe "#database_url=" do
    it "setting custom database URL works" do
      RubyPgExtras.database_url = ENV.fetch("DATABASE_URL")
      expect do
        RubyPgExtras.bloat(in_format: :hash)
      end.not_to raise_error
    end
  end
end
