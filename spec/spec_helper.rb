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
else
  "5432"
end

ENV["DATABASE_URL"] ||= "postgresql://postgres:secret@localhost:#{port}/ruby-pg-extras-test"
