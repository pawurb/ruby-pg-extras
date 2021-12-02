module RubyPGExtras
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
      end.map do |index_data|
        index_name = index_data.fetch("indexname")
        {
          index_name: index_data.fetch("indexname"),
          table_name: index_data.fetch("tablename"),
          columns: index_data.fetch("columns").split(',').map(&:strip),
          index_size: index_size_data.find do |el|
            el.fetch("name") == index_name
          end.fetch("size", "N/A"),
          index_scans:  index_scans_data.find do |el|
            el.fetch("index") == index_name
          end.fetch("index_scans", "N/A"),
          null_frac: null_indexes_data.find do |el|
            el.fetch("index") == index_name
          end&.fetch("null_frac", "N/A") || "0.00%"
        }
      end
    end

    def index_size_data
      @_index_size_data ||= query_module.index_size(in_format: :hash)
    end

    def null_indexes_data
      @_null_indexes_data ||= query_module.null_indexes(
        in_format: :hash,
        args: { min_relation_size_mb: 0 }
      )
    end

    def index_scans_data
      @_index_scans_data ||= query_module.index_scans(in_format: :hash)
    end

    def indexes_data
      @_indexes_data ||= query_module.indexes(in_format: :hash)
    end

    private

    def query_module
      RubyPGExtras
    end
  end
end
