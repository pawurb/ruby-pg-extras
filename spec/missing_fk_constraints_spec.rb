# frozen_string_literal: true

require "spec_helper"
require "ruby-pg-extras"

describe "#missing_fk_constraints" do
  it "detects missing foreign keys for all tables" do
    result = RubyPgExtras.missing_fk_constraints(in_format: :hash)
    expect(result).to match_array([
      { table: "users", column_name: "customer_id" },
      { table: "posts", column_name: "category_id" },
    ])
  end

  it "detects missing foreign_keys for a specific table" do
    result = RubyPgExtras.missing_fk_constraints(args: { table_name: "posts" }, in_format: :hash)

    expect(result).to eq([
      { table: "posts", column_name: "category_id" },
    ])
  end
end
