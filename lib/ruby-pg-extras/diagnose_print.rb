# frozen_string_literal: true

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
          colorize("[#{symbol}] - #{key}", color),
          colorize(val.fetch(:message), color)
        ]
      end

      puts Terminal::Table.new(
        title: title,
        rows: rows
      )
    end

    private

    def title
      "ruby-pg-extras - diagnose report"
    end

    def colorize(string, color)
      if color == :red
        "\e[0;31;49m#{string}\e[0m"
      elsif color == :green
        "\e[0;32;49m#{string}\e[0m"
      else
        raise "Unsupported color: #{color}"
      end
    end
  end
end
