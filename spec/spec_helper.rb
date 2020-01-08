# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require_relative '../lib/ruby-pg-extras'

ENV["DATABASE_URL"] ||= "postgresql://postgres:secret@localhost:5432/ruby-pg-extras-test"
