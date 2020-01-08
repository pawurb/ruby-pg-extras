# frozen_string_literal: true

require 'terminal-table'
require 'uri'
require 'pg'

module RubyPGExtras
  @@database_url = nil

  QUERIES = %i(
    bloat blocking cache_hit
    calls extensions
    index_size index_usage locks all_locks
    long_running_queries mandelbrot outliers
    records_rank seq_scans table_indexes_size
    table_size total_index_size total_table_size
    unused_indexes vacuum_stats
  )

  QUERIES.each do |query_name|
    define_singleton_method query_name do |options = { in_format: :display_table }|
      run_query(
        query_name: query_name,
        in_format: options.fetch(:in_format)
      )
    end
  end

  def self.run_query(query_name:, in_format:)
    result = connection.exec(
      sql_for(query_name: query_name)
    )

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

  %i(
    connection
    display_result
    sql_for
    sql_path_for
  ).each do |method_name|
    private_class_method method_name
  end
end

require 'ruby-pg-extras/railtie' if defined?(Rails)
