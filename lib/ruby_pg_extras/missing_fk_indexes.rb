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
          RubyPgExtras.table_size(in_format: :hash).map { |row| row.fetch("name") }
        end

      tables.reduce([]) do |agg, table|
        index_info = RubyPgExtras.index_info(args: { table_name: table }, in_format: :hash)
        schema = RubyPgExtras.table_schema(args: { table_name: table }, in_format: :hash)

        fk_columns = schema.filter_map do |row|
          row.fetch("column_name") if row.fetch("column_name") =~ /_id$/
        end

        fk_columns.each do |column_name|
          if index_info.none? { |row| row.fetch(:columns)[0] == column_name }
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
  end
end
