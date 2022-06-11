# frozen_string_literal: true

module RubyPgExtras
  class DiagnoseData
    PG_EXTRAS_TABLE_CACHE_HIT_MIN_EXPECTED = "0.985"
    PG_EXTRAS_INDEX_CACHE_HIT_MIN_EXPECTED = "0.985"
    PG_EXTRAS_UNUSED_INDEXES_MAX_SCANS = 20
    PG_EXTRAS_UNUSED_INDEXES_MIN_SIZE_BYTES = SizeParser.to_i("1 MB") # 1000000 bytes
    PG_EXTRAS_NULL_INDEXES_MIN_SIZE_MB = 1 # 1 MB
    PG_EXTRAS_NULL_MIN_NULL_FRAC_PERCENT = 50 # 50%
    PG_EXTRAS_BLOAT_MIN_VALUE = 10
    PG_EXTRAS_OUTLIERS_MIN_EXEC_RATIO = 33 # 33%

    def self.call
      new.call
    end

    def call
      [
        :table_cache_hit,
        :index_cache_hit,
        :unused_indexes,
        :null_indexes,
        :bloat,
        :duplicate_indexes
      ].yield_self do |checks|
        extensions_data = query_module.extensions(in_format: :hash)
        pg_stats_enabled = extensions_data.find do |el|
          el.fetch("name") == "pg_stat_statements"
        end.fetch("installed_version", false)

        ssl_info_enabled = extensions_data.find do |el|
          el.fetch("name") == "sslinfo"
        end.fetch("installed_version", false)

        if pg_stats_enabled
          checks = checks.concat([:outliers])
        end

        if ssl_info_enabled
          checks = checks.concat([:ssl_used])
        end

        checks
      end.map do |check|
        send(check).merge(check_name: check)
      end
    end

    private

    def query_module
      RubyPgExtras
    end

    def table_cache_hit
      min_expected = ENV.fetch(
        "PG_EXTRAS_TABLE_CACHE_HIT_MIN_EXPECTED",
        PG_EXTRAS_TABLE_CACHE_HIT_MIN_EXPECTED
      ).to_f

      table_cache_hit_ratio = query_module.cache_hit(in_format: :hash)[1].fetch("ratio").to_f.round(6)

      if table_cache_hit_ratio > min_expected
        {
          ok: true,
          message: "Table cache hit ratio is correct: #{table_cache_hit_ratio}."
        }
      else
        {
          ok: false,
          message: "Table hit ratio is too low: #{table_cache_hit_ratio}."
        }
      end
    end

    def index_cache_hit
      min_expected = ENV.fetch(
        "PG_EXTRAS_INDEX_CACHE_HIT_MIN_EXPECTED",
        PG_EXTRAS_INDEX_CACHE_HIT_MIN_EXPECTED
      ).to_f

      index_cache_hit_ratio = query_module.cache_hit(in_format: :hash)[0].fetch("ratio").to_f.round(6)

      if index_cache_hit_ratio > min_expected
        {
          ok: true,
          message: "Index hit ratio is correct: #{index_cache_hit_ratio}."
        }
      else
        {
          ok: false,
          message: "Index hit ratio is too low: #{index_cache_hit_ratio}."
        }
      end
    end

    def ssl_used
      ssl_connection = query_module.ssl_used(in_format: :hash)[0].fetch("ssl_is_used")

      if ssl_connection
        {
          ok: true,
          message: "Database client is using a secure SSL connection."
        }
      else
        {
          ok: false,
          message: "Database client is using an unencrypted connection."
        }
      end
    end

    def unused_indexes
      indexes = query_module.unused_indexes(
        in_format: :hash,
        args: { min_scans: PG_EXTRAS_UNUSED_INDEXES_MAX_SCANS }
      ).select do |i|
        SizeParser.to_i(i.fetch("index_size").strip) >= PG_EXTRAS_UNUSED_INDEXES_MIN_SIZE_BYTES
      end

      if indexes.count == 0
        {
          ok: true,
          message: "No unused indexes detected."
        }
      else
        print_indexes = indexes.map do |i|
          "'#{i.fetch('index')}' on '#{i.fetch('table')}' size #{i.fetch('index_size')}"
        end.join(",\n")
        {
          ok: false,
          message: "Unused indexes detected:\n#{print_indexes}"
        }
      end
    end

    def null_indexes
      indexes = query_module.null_indexes(
        in_format: :hash,
        args: { min_relation_size_mb: PG_EXTRAS_NULL_INDEXES_MIN_SIZE_MB }
      ).select do |i|
        i.fetch("null_frac").gsub("%", "").to_f >= PG_EXTRAS_NULL_MIN_NULL_FRAC_PERCENT
      end

      if indexes.count == 0
        {
          ok: true,
          message: "No null indexes detected."
        }
      else
        print_indexes = indexes.map do |i|
          "'#{i.fetch('index')}' size #{i.fetch('index_size')} null values fraction #{i.fetch('null_frac')}"
        end.join(",\n")
        {
          ok: false,
          message: "Null indexes detected:\n#{print_indexes}"
        }
      end
    end

    def bloat
      bloat_data = query_module.bloat(in_format: :hash).select do |b|
        b.fetch("bloat").to_f >= PG_EXTRAS_BLOAT_MIN_VALUE
      end

      if bloat_data.count == 0
        {
          ok: true,
          message: "No bloat detected."
        }
      else
        print_bloat = bloat_data.map do |b|
          "'#{b.fetch('object_name')}' bloat #{b.fetch('bloat')} waste #{b.fetch('waste')}"
        end.join(",\n")

        {
          ok: false,
          message: "Bloat detected:\n#{print_bloat}"
        }
      end
    end

    def duplicate_indexes
      indexes = query_module.duplicate_indexes(in_format: :hash)

      if indexes.count == 0
        {
          ok: true,
          message: "No duplicate indexes detected."
        }
      else
        print_indexes = indexes.map do |i|
          "'#{i.fetch('idx1')}' of size #{i.fetch('size')} is identical to '#{i.fetch('idx2')}'"
        end.join(",\n")

        {
          ok: false,
          message: "Duplicate indexes detected:\n#{print_indexes}"
        }
      end
    end

    def outliers
      queries = query_module.outliers(in_format: :hash).select do |q|
        q.fetch("prop_exec_time").gsub("%", "").to_f >= PG_EXTRAS_OUTLIERS_MIN_EXEC_RATIO
      end

      if queries.count == 0
        {
          ok: true,
          message: "No queries using significant execution ratio detected."
        }
      else
        print_queries = queries.map do |q|
          "'#{q.fetch('query').slice(0, 30)}...' called #{q.fetch('ncalls')} times, using #{q.fetch('prop_exec_time')} of total exec time."
        end.join(",\n")

        {
          ok: false,
          message: "Queries using significant execution ratio detected:\n#{print_queries}"
        }
      end
    end
  end
end
