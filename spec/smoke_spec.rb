# frozen_string_literal: true

require 'spec_helper'

describe RubyPGExtras do
  RubyPGExtras::QUERIES.each do |query_name|
    it "#{query_name} description can be read" do
      expect do
        RubyPGExtras.description_for(
          query_name: query_name
        )
      end.not_to raise_error
    end
  end

  PG_STATS_DEPENDENT_QUERIES = %i(calls outliers)

  (RubyPGExtras::QUERIES - PG_STATS_DEPENDENT_QUERIES).each do |query_name|
    it "#{query_name} query can be executed" do
      expect do
        RubyPGExtras.run_query(
          query_name: query_name,
          in_format: :hash
        )
      end.not_to raise_error
    end
  end
end
