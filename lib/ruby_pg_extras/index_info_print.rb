# frozen_string_literal: true

require "terminal-table"

module RubyPgExtras
  class IndexInfoPrint
    def self.call(data)
      new.call(data)
    end

    def call(data)
      rows = data.map do |el|
        [
          el.fetch(:index_name),
          el.fetch(:table_name),
          el.fetch(:columns).join(", "),
          # Included columns are displayed separately because they do not affect the index key order.
          el.fetch(:included_columns, []).join(", "),
          el.fetch(:index_method, "N/A"),
          el.fetch(:unique, false),
          el.fetch(:primary, false),
          el.fetch(:partial, false),
          el.fetch(:predicate, nil),
          el.fetch(:index_size),
          el.fetch(:index_scans),
          el.fetch(:null_frac),
        ]
      end

      puts Terminal::Table.new(
        headings: [
          "Index name",
          "Table name",
          "Columns",
          "Included columns",
          "Method",
          "Unique",
          "Primary",
          "Partial",
          "Predicate",
          "Index size",
          "Index scans",
          "Null frac",
        ],
        title: title,
        rows: rows,
      )
    end

    private

    def title
      "Index info"
    end
  end
end
