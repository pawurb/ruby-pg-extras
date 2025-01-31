# frozen_string_literal: true

require "spec_helper"
require "ruby-pg-extras"

describe "missing_fk_indexes" do
  it "detects missing indexes for all tables" do
    result = RubyPgExtras.missing_fk_indexes(in_format: :hash)
    expect(result.size).to eq(2)
    expect(result[0]).to eq({
      table: "users", column_name: "company_id",
    })
    expect(result[1]).to eq({
      table: "posts", column_name: "topic_id",
    })
  end

  it "detects missing indexes for specific table" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "posts" }, in_format: :hash)
    expect(result.size).to eq(1)
    expect(result[0]).to eq({
      table: "posts", column_name: "topic_id",
    })
  end
end
