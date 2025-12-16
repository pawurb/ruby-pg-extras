# frozen_string_literal: true

module RubyPgExtras
  # Parses and matches ignore patterns like:
  # - "*"              (ignore everything)
  # - "posts.*"        (ignore all columns on a table)
  # - "category_id"    (ignore this column name on all tables)
  # - "posts.topic_id" (ignore a specific table+column)
  class IgnoreList
    def initialize(ignore_list)
      @rules = normalize(ignore_list)
    end

    def ignored?(table:, column_name:)
      @rules.any? do |rule|
        next true if rule == "*"
        next true if rule == "#{table}.*"
        next true if rule == column_name
        next true if rule == "#{table}.#{column_name}"
        false
      end
    end

    private

    def normalize(ignore_list)
      entries =
        case ignore_list
        when nil
          []
        when String
          ignore_list.split(",")
        when Array
          ignore_list
        else
          raise ArgumentError, "ignore_list must be a String or Array"
        end

      entries
        .map { |v| v.to_s.strip }
        .reject(&:empty?)
        .uniq
    end
  end
end


