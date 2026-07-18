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

  describe "update_stats" do
    it "returns a consistent HOT update breakdown" do
      connection = RubyPgExtras.connection
      server_version_num = connection.exec("SHOW server_version_num").to_a[0].values[0].to_i

      # Keep this fixture local so every run starts with fresh statistics counters
      # and a controlled fillfactor for producing HOT and non-HOT updates.
      connection.exec("DROP TABLE IF EXISTS update_stats_test")
      connection.exec(<<~SQL)
        CREATE TABLE update_stats_test (
          id INTEGER PRIMARY KEY,
          value TEXT
        ) WITH (fillfactor = 80)
      SQL
      connection.exec("INSERT INTO update_stats_test VALUES (1, 'before')")
      # Updating the unindexed value column produces a HOT update.
      connection.exec("UPDATE update_stats_test SET value = 'after' WHERE id = 1")
      # Updating the primary key requires index maintenance, producing a non-HOT update.
      connection.exec("UPDATE update_stats_test SET id = 2 WHERE id = 1")
      # estimated_heap_bytes_per_live_row divides main-fork heap size by
      # pg_class.reltuples, which is only populated after ANALYZE (or VACUUM).
      connection.exec("ANALYZE update_stats_test")

      row = nil
      # PostgreSQL publishes cumulative statistics asynchronously, particularly
      # on older supported versions, so poll until both updates are visible.
      20.times do
        row = RubyPgExtras.update_stats(
          args: { schema: "public" },
          in_format: :hash,
        ).find { |result| result["table"] == "update_stats_test" }
        break if row && row["total_updates"].to_i == 2

        sleep 0.1
      end

      expect(row).not_to be_nil
      expect(row["fillfactor"].to_i).to eq(80)
      expect(row["estimated_heap_bytes_per_live_row"].to_i).to be > 0
      expect(row["total_updates"].to_i).to eq(2)
      expect(row["hot_updates"].to_i).to eq(1)

      if server_version_num >= 160000
        expect(row["same_page_non_hot_updates"].to_i).to eq(1)
        expect(row["new_page_updates"].to_i).to eq(0)
        expect(row["total_updates"].to_i).to eq(
          row["hot_updates"].to_i +
          row["same_page_non_hot_updates"].to_i +
          row["new_page_updates"].to_i,
        )
      else
        expect(row["non_hot_updates"].to_i).to eq(1)
        expect(row["total_updates"].to_i).to eq(
          row["hot_updates"].to_i + row["non_hot_updates"].to_i,
        )
      end
    ensure
      connection&.exec("DROP TABLE IF EXISTS update_stats_test")
    end
  end

  describe "#database_url=" do
    it "setting custom database URL works" do
      RubyPgExtras.database_url = ENV.fetch("DATABASE_URL")
      expect do
        RubyPgExtras.bloat(in_format: :hash)
      end.not_to raise_error
    end

    it "resets the connection when setting database URL" do
      old_connection = RubyPgExtras.connection
      expect(old_connection).not_to be_finished

      RubyPgExtras.database_url = ENV.fetch("DATABASE_URL")

      expect(old_connection).to be_finished
      new_connection = RubyPgExtras.connection
      expect(new_connection).not_to eq(old_connection)
      expect(new_connection).not_to be_finished
    end
  end
end
