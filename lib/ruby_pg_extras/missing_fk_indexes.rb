# frozen_string_literal: true

require "json"

module RubyPgExtras
  class MissingFkIndexes
    # ignore_list: array (or comma-separated string) of entries like:
    # - "posts.topic_id" (ignore a specific table+column)
    # - "topic_id"       (ignore this column name for all tables)
    # - "posts.*"        (ignore all columns on a table)
    # - "*"              (ignore everything)
    def self.call(table_name, ignore_list: nil)
      new.call(table_name, ignore_list: ignore_list)
    end

    def call(table_name, ignore_list: nil)
      ignore_list_matcher = IgnoreList.new(ignore_list)

      indexes_info = query_module.indexes(in_format: :hash)
      foreign_keys = query_module.foreign_keys(in_format: :hash)

      tables = if table_name
          [table_name]
        else
          foreign_keys.map { |row| row.fetch("table_name") }.uniq
        end

      tables.reduce([]) do |agg, table|
        index_info = indexes_info.select { |row| row.fetch("tablename") == table }
        table_fks = foreign_keys.select { |row| row.fetch("table_name") == table }

        table_fks.each do |fk|
          column_name = fk.fetch("column_name")

          # Skip columns explicitly excluded via ignore list.
          next if ignore_list_matcher.ignored?(table: table, column_name: column_name)

          if index_info.none? { |row| usable_index?(row, column_name: column_name) }
            agg.push(
              {
                table: table,
                column_name: column_name,
              }
            )
          end
        end

        agg
      end
    end

    private

    def usable_index?(row, column_name:)
      # A partial index cannot generally satisfy foreign key maintenance for every row.
      return false if boolean_value(row.fetch("is_partial", false))

      # PostgreSQL can use a composite index for FK checks only when the FK column is leftmost.
      first_key_column(row) == column_name
    end

    def first_key_column(row)
      # New index metadata exposes clean key column names; fall back for legacy/stubbed rows.
      if row.key?("key_column_names") && row.fetch("key_column_names") != nil
        JSON.parse(row.fetch("key_column_names")).first
      elsif row.key?("key_columns") && row.fetch("key_columns") != nil
        row.fetch("key_columns").split(",").map(&:strip).first
      else
        row.fetch("columns").split(",").map(&:strip).first
      end
    end

    def boolean_value(value)
      # PG::Result returns booleans as "t"/"f"; specs may provide real Ruby booleans.
      [true, "t", "true"].include?(value)
    end

    def query_module
      RubyPgExtras
    end
  end
end
