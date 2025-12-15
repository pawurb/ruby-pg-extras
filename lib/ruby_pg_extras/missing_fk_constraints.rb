# frozen_string_literal: true

module RubyPgExtras
  class MissingFkConstraints
    # ignore_list: array (or comma-separated string) of entries like:
    # - "posts.category_id" (ignore a specific table+column)
    # - "category_id"       (ignore this column name for all tables)
    # - "posts.*"           (ignore all columns on a table)
    # - "*"                 (ignore everything)
    def self.call(table_name, ignore_list: nil)
      new.call(table_name, ignore_list: ignore_list)
    end

    def call(table_name, ignore_list: nil)
      ignore_list_matcher = IgnoreList.new(ignore_list)

      tables =
        if table_name
          [table_name]
        else
          all_tables
        end

      schemas_by_table = query_module
        .table_schemas(in_format: :hash)
        .group_by { |row| row.fetch("table_name") }

      fk_columns_by_table = query_module
        .foreign_keys(in_format: :hash)
        .group_by { |row| row.fetch("table_name") }
        .transform_values { |rows| rows.map { |row| row.fetch("column_name") } }

      tables.each_with_object([]) do |table, agg|
        schema = schemas_by_table.fetch(table, [])
        fk_columns_for_table = fk_columns_by_table.fetch(table, [])
        schema_column_names = schema.map { |row| row.fetch("column_name") }

        candidate_fk_columns = schema.filter_map do |row|
          column_name = row.fetch("column_name")

          # Skip columns explicitly excluded via ignore list.
          next if ignore_list_matcher.ignored?(table: table, column_name: column_name)

          # Skip columns that already have a foreign key constraint on this table.
          next if fk_columns_for_table.include?(column_name)

          # Skip columns that don't look like an FK candidate based on naming conventions.
          next unless DetectFkColumn.call(column_name, all_tables)

          # Rails polymorphic associations use <name>_id + <name>_type and can't have FK constraints.
          candidate_prefix = column_name.delete_suffix("_id")
          polymorphic_type_column = "#{candidate_prefix}_type"
          # Skip polymorphic associations (cannot be expressed as a real FK constraint).
          next if schema_column_names.include?(polymorphic_type_column)

          column_name
        end

        candidate_fk_columns.each do |column_name|
          agg.push(
            {
              table: table,
              column_name: column_name,
            }
          )
        end
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
