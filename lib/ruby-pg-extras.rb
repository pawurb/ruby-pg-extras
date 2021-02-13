# frozen_string_literal: true

require 'terminal-table'
require 'uri'
require 'pg'

module RubyPGExtras
  @@database_url = nil

  QUERIES = %i(
    bloat blocking cache_hit
    calls extensions table_cache_hit index_cache_hit
    index_size index_usage null_indexes locks all_locks
    long_running_queries mandelbrot outliers
    records_rank seq_scans table_indexes_size
    table_size total_index_size total_table_size
    unused_indexes vacuum_stats kill_all
  )

  DEFAULT_ARGS = Hash.new({}).merge({
    calls: { limit: 10 },
    long_running_queries: { threshold: "500 milliseconds" },
    outliers: { limit: 10 },
    unused_indexes: { min_scans: 50 },
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
