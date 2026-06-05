# frozen_string_literal: true

require "json"

module RubyPgExtras
  class IndexInfo
    def self.call(table_name = nil)
      new.call(table_name)
    end

    def call(table_name = nil)
      indexes_data.select do |index_data|
        if table_name == nil
          true
        else
          index_data.fetch("tablename") == table_name
        end
      end.sort_by do |index_data|
        index_data.fetch("tablename")
      end.map do |index_data|
        index_name = index_data.fetch("indexname")

        {
          index_name: index_name,
          table_name: index_data.fetch("tablename"),
          # Prefer JSON arrays from indexes.sql so expressions containing commas are not split incorrectly.
          columns: array_value(index_data, json_key: "columns_json", fallback_key: "columns"),
          # Clean key column names are used separately from display columns that may include opclasses/order/collations.
          key_columns: array_value(index_data, json_key: "key_column_names", fallback_key: "key_columns"),
          # INCLUDE columns are stored separately because they are not part of the index search key.
          included_columns: array_value(index_data, json_key: "included_columns_json", fallback_key: "included_columns"),
          index_method: index_data.fetch("index_method", "N/A"),
          unique: boolean_value(index_data.fetch("is_unique", false)),
          primary: boolean_value(index_data.fetch("is_primary", false)),
          partial: boolean_value(index_data.fetch("is_partial", false)),
          predicate: index_data.fetch("predicate", nil),
          index_size: index_size_data.find do |el|
            el.fetch("name") == index_name
          end.fetch("size", "N/A"),
          index_scans: index_scans_data.find do |el|
            el.fetch("index") == index_name
          end.fetch("index_scans", "N/A"),
          null_frac: null_indexes_data.find do |el|
            el.fetch("index") == index_name
          end&.fetch("null_frac", "N/A")&.strip || "0.00%",
        }
      end
    end

    def index_size_data
      @_index_size_data ||= query_module.index_size(in_format: :hash)
    end

    def null_indexes_data
      @_null_indexes_data ||= query_module.null_indexes(
        in_format: :hash,
        args: { min_relation_size_mb: 0 },
      )
    end

    def index_scans_data
      @_index_scans_data ||= query_module.index_scans(in_format: :hash)
    end

    def indexes_data
      @_indexes_data ||= query_module.indexes(in_format: :hash)
    end

    private

    def array_value(index_data, json_key:, fallback_key:)
      # Older/stubbed callers may only provide comma-separated fields, so keep a fallback path.
      if index_data.key?(json_key) && index_data.fetch(json_key) != nil
        JSON.parse(index_data.fetch(json_key)).compact
      elsif index_data.key?(fallback_key) && index_data.fetch(fallback_key) != nil
        index_data.fetch(fallback_key).split(",").map(&:strip).reject(&:empty?)
      else
        []
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
