# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ruby_pg_extras/version"

Gem::Specification.new do |s|
  s.name = "ruby-pg-extras"
  s.version = RubyPgExtras::VERSION
  s.authors = ["pawurb"]
  s.email = ["contact@pawelurbanek.com"]
  s.summary = %q{ Ruby PostgreSQL performance database insights }
  s.description = %q{ Ruby port of Heroku PG Extras. The goal of this project is to provide a powerful insights into PostgreSQL database for Ruby on Rails apps that are not using the default Heroku PostgreSQL plugin. }
  s.homepage = "http://github.com/pawurb/ruby-pg-extras"
  s.files = `git ls-files`.split("\n")
  s.test_files = s.files.grep(%r{^(spec)/})
  s.require_paths = ["lib"]
  s.license = "MIT"
  s.add_dependency "pg"
  s.add_dependency "terminal-table"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rufo"
  s.add_development_dependency "dbg-rb"

  if s.respond_to?(:metadata=)
    s.metadata = { "rubygems_mfa_required" => "true" }
  end
end
