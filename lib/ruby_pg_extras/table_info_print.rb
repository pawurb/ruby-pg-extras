# frozen_string_literal: true

require 'terminal-table'

module RubyPgExtras
  class TableInfoPrint
    def self.call(data)
      new.call(data)
    end

    def call(data)
      rows = data.map do |el|
        [
          el.fetch(:table_name),
          el.fetch(:table_size),
          el.fetch(:table_cache_hit),
          el.fetch(:indexes_cache_hit),
          el.fetch(:estimated_rows),
          el.fetch(:sequential_scans),
          el.fetch(:indexes_scans)
        ]
      end

      puts Terminal::Table.new(
        headings: [
          "Table name",
          "Table size",
          "Table cache hit",
          "Indexes cache hit",
          "Estimated rows",
          "Sequential scans",
          "Indexes scans"
        ],
        title: title,
        rows: rows
      )
    end

    private

    def title
      "Table info"
    end
  end
end
