# frozen_string_literal: true

module RubyPgExtras
  class SizeParser
    def self.to_i(arg)
      value = to_i_si(arg) || to_i_binary(arg) || to_i_digits(arg)
      raise ArgumentError, "Unparseable size: #{arg}" if value.nil?

      value
    end

    def self.regexp_for_units(units)
      /\A(-?\d+)\s?(#{units.join('|')})\z/i
    end

    SI_UNITS = %w[bytes kB MB GB TB PB EB ZB YB].map(&:downcase).freeze
    SI_REGEXP = regexp_for_units(SI_UNITS)

    def self.to_i_si(arg)
      to_i_for_units(arg, SI_REGEXP, SI_UNITS, 1000)
    end

    BINARY_UNITS = %w[bytes KiB MiB GiB TiB PiB EiB ZiB YiB].map(&:downcase).freeze
    BINARY_REGEXP = regexp_for_units(BINARY_UNITS)

    def self.to_i_binary(arg)
      to_i_for_units(arg, BINARY_REGEXP, BINARY_UNITS, 1024)
    end

    def self.to_i_for_units(arg, regexp, units, multiplier)
      match_data = regexp.match(arg)
      return nil unless match_data

      exponent = units.index(match_data[2].downcase).to_i
      match_data[1].to_i * multiplier**exponent
    end

    DIGITS_ONLY_REGEXP = /\A(-?\d+)\z/.freeze
    def self.to_i_digits(arg)
      DIGITS_ONLY_REGEXP.match?(arg) ? arg.to_i : nil
    end
  end
end
