# frozen_string_literal: true

module RubyPgExtras
  class DetectFkColumn
    PLURAL_RULES = [
      [/s$/i, "s"],
      [/^(ax|test)is$/i, '\1es'],
      [/(octop|vir)us$/i, '\1i'],
      [/(alias|status)$/i, '\1es'],
      [/(bu)s$/i, '\1ses'],
      [/(buffal|tomat)o$/i, '\1oes'],
      [/([ti])um$/i, '\1a'],
      [/sis$/i, "ses"],
      [/(?:([^f])fe|([lr])f)$/i, '\1\2ves'],
      [/([^aeiouy]|qu)y$/i, '\1ies'],
      [/(x|ch|ss|sh)$/i, '\1es'],
      [/(matr|vert|ind)(?:ix|ex)$/i, '\1ices'],
      [/^(m|l)ouse$/i, '\1ice'],
      [/^(ox)$/i, '\1en'],
      [/(quiz)$/i, '\1zes'],
    ]
    IRREGULAR = {
      "person" => "people",
      "man" => "men",
      "child" => "children",
      "sex" => "sexes",
      "move" => "moves",
      "zombie" => "zombies",
    }
    UNCOUNTABLE = %w(equipment information rice money species series fish sheep jeans police)

    def self.call(column_name, tables)
      new.call(column_name, tables)
    end

    def call(column_name, tables)
      return false unless column_name =~ /_id$/
      table_name = column_name.split("_").first
      table_name = pluralize(table_name)
      tables.include?(table_name)
    end

    def pluralize(word)
      return word if UNCOUNTABLE.include?(word.downcase)
      return IRREGULAR[word] if IRREGULAR.key?(word)
      return IRREGULAR.invert[word] if IRREGULAR.value?(word)

      PLURAL_RULES.reverse.each do |(rule, replacement)|
        return word.gsub(rule, replacement) if word.match?(rule)
      end
      word + "s"
    end
  end
end
