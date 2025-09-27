# frozen_string_literal: true

module RubyPgExtras
  class MissingFkIndexes
    def self.call(table_name)
      new.call(table_name)
    end

    def call(table_name)
      tables = if table_name
          [table_name]
        else
          all_tables
        end

      indexes_info = query_module.indexes(in_format: :hash)
      schemas = query_module.table_schemas(in_format: :hash)

      tables.reduce([]) do |agg, table|
        index_info = indexes_info.select { |row| row.fetch("tablename") == table }
        schema = schemas.select { |row| row.fetch("table_name") == table }

        fk_columns = schema.filter_map do |row|
          if DetectFkColumn.call(row.fetch("column_name"), all_tables)
            row.fetch("column_name")
          end
        end

        fk_columns.each do |column_name|
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

    def all_tables
      @_all_tables ||= query_module.table_size(in_format: :hash).map { |row| row.fetch("name") }
    end

    def query_module
      RubyPgExtras
    end
  end
end
