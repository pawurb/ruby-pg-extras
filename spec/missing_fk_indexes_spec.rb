# frozen_string_literal: true

require "spec_helper"
require "ruby-pg-extras"

describe "missing_fk_indexes" do
  it "detects missing indexes for all tables" do
    result = RubyPgExtras.missing_fk_indexes(in_format: :hash)
    expect(result).to match_array([
      { table: "expression_indexed_posts", column_name: "topic_id" },
      { table: "partial_indexed_posts", column_name: "topic_id" },
      { table: "posts", column_name: "topic_id" },
    ])
  end

  it "detects foreign keys that are only indexed after another column" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "posts" }, in_format: :hash)

    # posts.topic_id exists in index_posts_on_user_id, but not as the leftmost key column.
    expect(result).to eq([
      { table: "posts", column_name: "topic_id" },
    ])
  end

  it "supports ignoring a specific table+column via args" do
    result = RubyPgExtras.missing_fk_indexes(
      args: { ignore_list: ["posts.topic_id"] },
      in_format: :hash
    )

    expect(result).to eq([
      { table: "expression_indexed_posts", column_name: "topic_id" },
      { table: "partial_indexed_posts", column_name: "topic_id" },
    ])
  end

  it "supports ignoring a column name globally via args" do
    result = RubyPgExtras.missing_fk_indexes(
      args: { ignore_list: ["company_id"] },
      in_format: :hash
    )

    expect(result).to match_array([
      { table: "expression_indexed_posts", column_name: "topic_id" },
      { table: "partial_indexed_posts", column_name: "topic_id" },
      { table: "posts", column_name: "topic_id" },
    ])
  end

  it "does not flag foreign keys covered by sorted indexes" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "users" }, in_format: :hash)

    # users.company_id is leftmost in a sorted index, so it still supports FK checks.
    expect(result).to eq([])
  end

  it "detects foreign keys covered only by an expression index" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "expression_indexed_posts" }, in_format: :hash)

    # Expression indexes do not support raw FK lookups such as WHERE topic_id = ?.
    expect(result).to eq([
      { table: "expression_indexed_posts", column_name: "topic_id" },
    ])
  end

  it "detects foreign keys covered only by a partial index" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "partial_indexed_posts" }, in_format: :hash)

    # Partial indexes do not generally cover all rows needed for FK maintenance.
    expect(result).to eq([
      { table: "partial_indexed_posts", column_name: "topic_id" },
    ])
  end

  it "does not flag foreign keys covered by indexes with included columns" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "included_indexed_posts" }, in_format: :hash)

    # INCLUDE columns are ignored for key matching; topic_id is still the leftmost key column.
    expect(result).to eq([])
  end

  it "does not flag foreign keys covered by indexes with operator classes" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "opclass_indexed_codes" }, in_format: :hash)

    # The display column includes text_pattern_ops, but the logical key column remains code.
    expect(result).to eq([])
  end

  it "does not flag foreign keys covered by indexes with collations" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "collated_indexed_codes" }, in_format: :hash)

    # The display column includes COLLATE "C", but the logical key column remains code.
    expect(result).to eq([])
  end

  it "does not flag foreign keys covered by sorted indexes on their own table" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "sorted_indexed_posts" }, in_format: :hash)

    expect(result).to eq([])
  end
end
