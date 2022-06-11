# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require_relative '../lib/ruby-pg-extras'

pg_version = ENV["PG_VERSION"]

port = if pg_version == "11"
  "5432"
elsif pg_version == "12"
  "5433"
elsif pg_version == "13"
  "5434"
elsif pg_version == "14"
  "5435"
else
  "5432"
end

ENV["DATABASE_URL"] ||= "postgresql://postgres:secret@localhost:#{port}/ruby-pg-extras-test"

RSpec.configure do |config|
  config.before(:suite) do
    RubyPgExtras.connection.exec("CREATE EXTENSION IF NOT EXISTS pg_stat_statements;")
    RubyPgExtras.connection.exec("CREATE EXTENSION IF NOT EXISTS pg_buffercache;")
    RubyPgExtras.connection.exec("CREATE EXTENSION IF NOT EXISTS sslinfo;")
  end
end
