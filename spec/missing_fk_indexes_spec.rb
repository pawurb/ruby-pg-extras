# frozen_string_literal: true

require "spec_helper"
require "ruby-pg-extras"

describe "missing_fk_indexes" do
  it "detects missing indexes for all tables" do
    result = RubyPgExtras.missing_fk_indexes(in_format: :hash)
    expect(result).to match_array([
      { table: "expression_not_null_partial_indexed_posts", column_name: "topic_id" },
      { table: "expression_indexed_posts", column_name: "topic_id" },
      { table: "null_partial_indexed_posts", column_name: "topic_id" },
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

    expect(result).to match_array([
      { table: "expression_not_null_partial_indexed_posts", column_name: "topic_id" },
      { table: "expression_indexed_posts", column_name: "topic_id" },
      { table: "null_partial_indexed_posts", column_name: "topic_id" },
      { table: "partial_indexed_posts", column_name: "topic_id" },
    ])
  end

  it "supports ignoring a column name globally via args" do
    result = RubyPgExtras.missing_fk_indexes(
      args: { ignore_list: ["company_id"] },
      in_format: :hash
    )

    expect(result).to match_array([
      { table: "expression_not_null_partial_indexed_posts", column_name: "topic_id" },
      { table: "expression_indexed_posts", column_name: "topic_id" },
      { table: "null_partial_indexed_posts", column_name: "topic_id" },
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

  it "detects foreign keys covered by an expression index with a not-null predicate" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "expression_not_null_partial_indexed_posts" }, in_format: :hash)

    # The predicate is compatible, but the index key is topic_id::text rather than raw topic_id.
    expect(result).to eq([
      { table: "expression_not_null_partial_indexed_posts", column_name: "topic_id" },
    ])
  end

  it "detects foreign keys covered only by a partial index with an unrelated predicate" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "partial_indexed_posts" }, in_format: :hash)

    # WHERE id > 0 is unrelated to topic_id and does not guarantee coverage for every FK value.
    expect(result).to eq([
      { table: "partial_indexed_posts", column_name: "topic_id" },
    ])
  end

  it "does not flag foreign keys covered by a not-null partial index" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "not_null_partial_indexed_posts" }, in_format: :hash)

    # FK checks only need non-null values, so WHERE topic_id IS NOT NULL still covers them.
    expect(result).to eq([])
  end

  it "normalizes nested parentheses around not-null predicates" do
    allow(RubyPgExtras).to receive(:indexes).and_return([
      {
        "tablename" => "stubbed_posts",
        "columns" => "topic_id",
        "key_column_names" => '["topic_id"]',
        "is_partial" => "t",
        "predicate" => "((topic_id IS NOT NULL))",
      },
    ])
    allow(RubyPgExtras).to receive(:foreign_keys).and_return([
      { "table_name" => "stubbed_posts", "column_name" => "topic_id" },
    ])

    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "stubbed_posts" }, in_format: :hash)

    expect(result).to eq([])
  end

  it "detects foreign keys covered only by a null partial index" do
    result = RubyPgExtras.missing_fk_indexes(args: { table_name: "null_partial_indexed_posts" }, in_format: :hash)

    # WHERE topic_id IS NULL cannot support FK lookups for concrete topic_id values.
    expect(result).to eq([
      { table: "null_partial_indexed_posts", column_name: "topic_id" },
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
