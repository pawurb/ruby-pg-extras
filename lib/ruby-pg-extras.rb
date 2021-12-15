# frozen_string_literal: true

require 'terminal-table'
require 'uri'
require 'pg'
require 'ruby-pg-extras/diagnose_data'
require 'ruby-pg-extras/diagnose_print'
require 'ruby-pg-extras/index_info'
require 'ruby-pg-extras/index_info_print'
require 'ruby-pg-extras/table_info'
require 'ruby-pg-extras/table_info_print'

module RubyPGExtras
  @@database_url = nil
  NEW_PG_STAT_STATEMENTS = "1.8"

  QUERIES = %i(
    add_extensions bloat blocking cache_hit db_settings
    calls extensions table_cache_hit tables index_cache_hit
    indexes index_size index_usage index_scans null_indexes locks all_locks
    long_running_queries mandelbrot outliers
    records_rank seq_scans table_index_scans table_indexes_size
    table_size total_index_size total_table_size
    unused_indexes duplicate_indexes vacuum_stats kill_all
    pg_stat_statements_reset buffercache_stats
    buffercache_usage ssl_used
  )

  DEFAULT_ARGS = Hash.new({}).merge({
    calls: { limit: 10 },
    calls_legacy: { limit: 10 },
    long_running_queries: { threshold: "500 milliseconds" },
    outliers: { limit: 10 },
    outliers_legacy: { limit: 10 },
    buffercache_stats: { limit: 10 },
    buffercache_usage: { limit: 20 },
    unused_indexes: { max_scans: 50 },
    null_indexes: { min_relation_size_mb: 10 }
  })

  QUERIES.each do |query_name|
    define_singleton_method query_name do |options = {}|
      run_query(
        query_name: query_name,
        in_format: options.fetch(:in_format, :display_table),
        args: options.fetch(:args, {})
      )
    end
  end

  def self.run_query(query_name:, in_format:, args: {})
    if %i(calls outliers).include?(query_name)
      pg_stat_statements_ver = RubyPGExtras.connection.exec("select installed_version from pg_available_extensions where name='pg_stat_statements'")
        .to_a[0].fetch("installed_version", nil)
      if pg_stat_statements_ver != nil
        if Gem::Version.new(pg_stat_statements_ver) < Gem::Version.new(NEW_PG_STAT_STATEMENTS)
          query_name = "#{query_name}_legacy".to_sym
        end
      end
    end

    sql = if (custom_args = DEFAULT_ARGS[query_name].merge(args)) != {}
      sql_for(query_name: query_name) % custom_args
    else
      sql_for(query_name: query_name)
    end
    result = connection.exec(sql)

    display_result(
      result,
      title: description_for(query_name: query_name),
      in_format: in_format
    )
  end

  def self.diagnose(in_format: :display_table)
    data = RubyPGExtras::DiagnoseData.call

    if in_format == :display_table
      RubyPGExtras::DiagnosePrint.call(data)
    elsif in_format == :hash
      data
    elsif in_format == :array
      data.map(&:values)
    else
      raise "Invalid 'in_format' argument!"
    end
  end

  def self.index_info(args: {}, in_format: :display_table)
    data = RubyPGExtras::IndexInfo.call(args[:table_name])

    if in_format == :display_table
      RubyPGExtras::IndexInfoPrint.call(data)
    elsif in_format == :hash
      data
    elsif in_format == :array
      data.map(&:values)
    else
      raise "Invalid 'in_format' argument!"
    end
  end

  def self.table_info(args: {}, in_format: :display_table)
    data = RubyPGExtras::TableInfo.call(args[:table_name])

    if in_format == :display_table
      RubyPGExtras::TableInfoPrint.call(data)
    elsif in_format == :hash
      data
    elsif in_format == :array
      data.map(&:values)
    else
      raise "Invalid 'in_format' argument!"
    end
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
        rows: result.values
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
    File.join(File.dirname(__FILE__), "/ruby-pg-extras/queries/#{query_name}.sql")
  end

  def self.connection
    database_uri = URI.parse(database_url)

    @_connection ||= PG.connect(
      dbname: database_uri.path[1..-1],
      host: database_uri.host,
      port: database_uri.port,
      user: database_uri.user,
      password: database_uri.password
    )
  end

  def self.database_url=(value)
    @@database_url = value
  end

  def self.database_url
    @@database_url || ENV.fetch("DATABASE_URL")
  end
end
