# frozen_string_literal: true

module RubyPgExtras
  class MissingFkIndexes
    def self.call(table_name)
      new.call(table_name)
    end

    def call(table_name)
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

          if index_info.none? { |row| row.fetch("columns").split(",").first == column_name }
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

    def query_module
      RubyPgExtras
    end
  end
end
