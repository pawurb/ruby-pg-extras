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
