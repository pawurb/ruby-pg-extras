# frozen_string_literal: true

module RubyPgExtras
  class MissingFkConstraints
    def self.call(table_name)
      new.call(table_name)
    end

    def call(table_name)
      tables = if table_name
          [table_name]
        else
          all_tables
        end

      tables.reduce([]) do |agg, table|
        foreign_keys_info = query_module.table_foreign_keys(args: { table_name: table }, in_format: :hash)
        schema = query_module.table_schema(args: { table_name: table }, in_format: :hash)

        fk_columns = schema.filter_map do |row|
          if DetectFkColumn.call(row.fetch("column_name"), all_tables)
            row.fetch("column_name")
          end
        end

        fk_columns.each do |column_name|
          if foreign_keys_info.none? { |row| row.fetch("column_name") == column_name }
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
