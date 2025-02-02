# frozen_string_literal: true

require "terminal-table"
require "uri"
require "pg"
require "ruby_pg_extras/size_parser"
require "ruby_pg_extras/diagnose_data"
require "ruby_pg_extras/diagnose_print"
require "ruby_pg_extras/missing_fk_indexes"
require "ruby_pg_extras/missing_fk_constraints"
require "ruby_pg_extras/index_info"
require "ruby_pg_extras/index_info_print"
require "ruby_pg_extras/table_info"
require "ruby_pg_extras/table_info_print"

module RubyPgExtras
  @@database_url = nil
  NEW_PG_STAT_STATEMENTS = "1.8"
  PG_STAT_STATEMENTS_17 = "1.11"

  QUERIES = %i(
    add_extensions bloat blocking cache_hit db_settings
    calls extensions table_cache_hit tables index_cache_hit
    indexes index_size index_usage index_scans null_indexes locks all_locks
    long_running_queries mandelbrot outliers
    records_rank seq_scans table_index_scans table_indexes_size
    table_size total_index_size total_table_size
    unused_indexes duplicate_indexes vacuum_stats kill_all kill_pid
    pg_stat_statements_reset buffercache_stats
    buffercache_usage ssl_used connections
    table_schema table_foreign_keys
  )

  DEFAULT_SCHEMA = ENV["PG_EXTRAS_SCHEMA"] || "public"

  REQUIRED_ARGS = {
    table_schema: [:table_name],
    table_foreign_keys: [:table_name],
  }

  DEFAULT_ARGS = Hash.new({}).merge({
    calls: { limit: 10 },
    calls_legacy: { limit: 10 },
    calls_17: { limit: 10 },
    long_running_queries: { threshold: "500 milliseconds" },
    locks: { limit: 20 },
    blocking: { limit: 20 },
    outliers: { limit: 10 },
    outliers_legacy: { limit: 10 },
    outliers_17: { limit: 10 },
    buffercache_stats: { limit: 10 },
    buffercache_usage: { limit: 20 },
    unused_indexes: { max_scans: 50, schema: DEFAULT_SCHEMA },
    null_indexes: { min_relation_size_mb: 10 },
    index_usage: { schema: DEFAULT_SCHEMA },
    index_cache_hit: { schema: DEFAULT_SCHEMA },
    table_cache_hit: { schema: DEFAULT_SCHEMA },
    index_scans: { schema: DEFAULT_SCHEMA },
    cache_hit: { schema: DEFAULT_SCHEMA },
    seq_scans: { schema: DEFAULT_SCHEMA },
    table_index_scans: { schema: DEFAULT_SCHEMA },
    records_rank: { schema: DEFAULT_SCHEMA },
    tables: { schema: DEFAULT_SCHEMA },
    kill_pid: { pid: 0 },
  })

  QUERIES.each do |query_name|
    define_singleton_method query_name do |options = {}|
      run_query(
        query_name: query_name,
        in_format: options.fetch(:in_format, :display_table),
        args: options.fetch(:args, {}),
      )
    end
  end

  def self.run_query_base(query_name:, conn:, exec_method:, in_format:, args: {})
    if %i(calls outliers).include?(query_name)
      pg_stat_statements_ver = conn.send(exec_method, "select installed_version from pg_available_extensions where name='pg_stat_statements'")
        .to_a[0].fetch("installed_version", nil)
      if pg_stat_statements_ver != nil
        if Gem::Version.new(pg_stat_statements_ver) < Gem::Version.new(NEW_PG_STAT_STATEMENTS)
          query_name = "#{query_name}_legacy".to_sym
        elsif Gem::Version.new(pg_stat_statements_ver) >= Gem::Version.new(PG_STAT_STATEMENTS_17)
          query_name = "#{query_name}_17".to_sym
        end
      end
    end

    REQUIRED_ARGS.fetch(query_name) { [] }.each do |arg_name|
      if args[arg_name].nil?
        raise ArgumentError, "'#{arg_name}' is required"
      end
    end

    sql = if (custom_args = DEFAULT_ARGS.fetch(query_name, {}).merge(args)) != {}
        sql_for(query_name: query_name) % custom_args
      else
        sql_for(query_name: query_name)
      end
    result = conn.send(exec_method, sql)

    display_result(
      result,
      title: description_for(query_name: query_name),
      in_format: in_format,
    )
  end

  def self.run_query(query_name:, in_format:, args: {})
    run_query_base(
      query_name: query_name,
      conn: connection,
      exec_method: :exec,
      in_format: in_format,
      args: args,
    )
  end

  def self.diagnose(in_format: :display_table)
    data = RubyPgExtras::DiagnoseData.call

    if in_format == :display_table
      RubyPgExtras::DiagnosePrint.call(data)
    elsif in_format == :hash
      data
    elsif in_format == :array
      data.map(&:values)
    else
      raise "Invalid 'in_format' argument!"
    end
  end

  def self.index_info(args: {}, in_format: :display_table)
    data = RubyPgExtras::IndexInfo.call(args[:table_name])

    if in_format == :display_table
      RubyPgExtras::IndexInfoPrint.call(data)
    elsif in_format == :hash
      data
    elsif in_format == :array
      data.map(&:values)
    else
      raise "Invalid 'in_format' argument!"
    end
  end

  def self.table_info(args: {}, in_format: :display_table)
    data = RubyPgExtras::TableInfo.call(args[:table_name])

    if in_format == :display_table
      RubyPgExtras::TableInfoPrint.call(data)
    elsif in_format == :hash
      data
    elsif in_format == :array
      data.map(&:values)
    else
      raise "Invalid 'in_format' argument!"
    end
  end

  def self.missing_fk_indexes(args: {}, in_format: :display_table)
    RubyPgExtras::MissingFkIndexes.call(args[:table_name])
  end

  def self.missing_fk_constraints(args: {}, in_format: :display_table)
    RubyPgExtras::MissingFkConstraints.call(args[:table_name])
  end

  def self.display_result(result, title:, in_format:)
    case in_format
    when :array
      result.values
    when :hash
      result.to_a
    when :raw
      result
    when :display_table
      headings = if result.count > 0
          result[0].keys
        else
          ["No results"]
        end

      puts Terminal::Table.new(
        title: title,
        headings: headings,
        rows: (result.try(:values) || result.map(&:values)),
      )
    else
      raise "Invalid in_format option"
    end
  end

  def self.description_for(query_name:)
    first_line = File.open(
      sql_path_for(query_name: query_name)
    ) { |f| f.readline }

    first_line[/\/\*(.*?)\*\//m, 1].strip
  end

  def self.sql_for(query_name:)
    File.read(
      sql_path_for(query_name: query_name)
    )
  end

  def self.sql_path_for(query_name:)
    File.join(File.dirname(__FILE__), "/ruby_pg_extras/queries/#{query_name}.sql")
  end

  def self.connection
    @_connection ||= PG.connect(database_url)
  end

  def self.database_url=(value)
    @@database_url = value
  end

  def self.database_url
    @@database_url || ENV["RUBY_PG_EXTRAS_DATABASE_URL"] || ENV.fetch("DATABASE_URL")
  end
end
