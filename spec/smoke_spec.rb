# frozen_string_literal: true

require 'spec_helper'

describe RubyPgExtras do
  RubyPgExtras::QUERIES.each do |query_name|
    it "#{query_name} description can be read" do
      expect do
        RubyPgExtras.description_for(
          query_name: query_name
        )
      end.not_to raise_error
    end
  end

  RubyPgExtras::QUERIES.each do |query_name|
    it "#{query_name} query can be executed" do
      expect do
        RubyPgExtras.run_query(
          query_name: query_name,
          in_format: :hash
        )
      end.not_to raise_error
    end
  end

  describe "#database_url=" do
    it "setting custom database URL works" do
      RubyPgExtras.database_url = ENV.fetch("DATABASE_URL")
      expect do
        RubyPgExtras.bloat(in_format: :hash)
      end.not_to raise_error
    end
  end
end
