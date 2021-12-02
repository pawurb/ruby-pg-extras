module RubyPGExtras
  class TableInfo
    def self.call(table_name = nil)
      new.call(table_name)
    end

    def call(table_name)
      tables_data.select do |table_data|
        if table_name == nil
          true
        else
          table_data.fetch("tablename") == table_name
        end
      end.map do |table_data|
        table_name = table_data.fetch("tablename")

        {
          table_name: table_name,
          table_size: table_size_data.find do |el|
            el.fetch("name") == table_name
          end.fetch("size", "N/A"),
          table_cache_hit: table_cache_hit_data.find do |el|
            el.fetch("name") == table_name
          end.fetch("ratio", "N/A"),
          indexes_cache_hit: index_cache_hit_data.find do |el|
            el.fetch("name") == table_name
          end.fetch("ratio", "N/A"),
          estimated_rows: records_rank_data.find do |el|
            el.fetch("name") == table_name
          end.fetch("estimated_count", "N/A"),
          sequential_scans: seq_scans_data.find do |el|
            el.fetch("name") == table_name
          end.fetch("count", "N/A"),
          indexes_scans: table_index_scans_data.find do |el|
            el.fetch("name") == table_name
          end.fetch("count", "N/A")
        }
      end
    end

    private

    def index_cache_hit_data
      @_index_cache_hit_data ||= query_module.index_cache_hit(in_format: :hash)
    end

    def table_cache_hit_data
      @_table_cache_hit_data ||= query_module.table_cache_hit(in_format: :hash)
    end

    def table_size_data
      @_table_size_data ||= query_module.table_size(in_format: :hash)
    end

    def records_rank_data
      @_records_rank_data ||= query_module.records_rank(in_format: :hash)
    end

    def tables_data
      @_tables_data ||= query_module.tables(in_format: :hash)
    end

    def seq_scans_data
      @_seq_scans_data ||= query_module.seq_scans(in_format: :hash)
    end

    def table_index_scans_data
      @_table_index_scans_data ||= query_module.table_index_scans(in_format: :hash)
    end

    def query_module
      RubyPGExtras
    end
  end
end
