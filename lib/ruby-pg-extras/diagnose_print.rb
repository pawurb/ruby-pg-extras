# frozen_string_literal: true

require 'colorize'
require 'terminal-table'

module RubyPGExtras
  class DiagnosePrint
    def self.call(data)
      new.call(data)
    end

    def call(data)
      rows = data.sort do |key|
        key[1].fetch(:ok) ? 1 : -1
      end.map do |el|
        key = el[0]
        val = el[1]
        symbol = val.fetch(:ok) ? "√" : "x"
        color = val.fetch(:ok) ? :green : :red

        [
          "[#{symbol}] - #{key}".colorize(color),
          val.fetch(:message).colorize(color)
        ]
      end

      puts Terminal::Table.new(
        title: title,
        rows: rows
      )
    end

    private

    def title
      "rails-pg-extras - diagnose report"
    end
  end
end
