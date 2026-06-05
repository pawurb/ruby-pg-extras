# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require_relative "../lib/ruby-pg-extras"

pg_version = ENV["PG_VERSION"]

PG_PORTS = {
  "13" => "5433",
  "14" => "5434",
  "15" => "5435",
  "16" => "5436",
  "17" => "5437",
  "18" => "5438",
}

port = PG_PORTS.fetch(pg_version, "5438")

ENV["DATABASE_URL"] ||= "postgresql://postgres:secret@localhost:#{port}/ruby-pg-extras-test"

RSpec.configure do |config|
  config.before(:suite) do
    DB_SCHEMA = <<-SQL
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS collated_indexed_codes;
DROP TABLE IF EXISTS opclass_indexed_codes;
DROP TABLE IF EXISTS included_indexed_posts;
DROP TABLE IF EXISTS sorted_indexed_posts;
DROP TABLE IF EXISTS partial_indexed_posts;
DROP TABLE IF EXISTS expression_indexed_posts;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS codes;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS topics;
DROP TABLE IF EXISTS companies;

CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255),
    company_id INTEGER,
    customer_id INTEGER,
    CONSTRAINT fk_users_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255)
);

CREATE TABLE codes (
    code TEXT PRIMARY KEY
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    topic_id INTEGER,
    category_id INTEGER,
    external_id INTEGER,
    title VARCHAR(255),
    CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_posts_topic FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);

CREATE TABLE expression_indexed_posts (
    id SERIAL PRIMARY KEY,
    topic_id INTEGER,
    CONSTRAINT fk_expression_indexed_posts_topic FOREIGN KEY (topic_id) REFERENCES topics(id)
);

CREATE TABLE partial_indexed_posts (
    id SERIAL PRIMARY KEY,
    topic_id INTEGER,
    CONSTRAINT fk_partial_indexed_posts_topic FOREIGN KEY (topic_id) REFERENCES topics(id)
);

CREATE TABLE sorted_indexed_posts (
    id SERIAL PRIMARY KEY,
    topic_id INTEGER,
    CONSTRAINT fk_sorted_indexed_posts_topic FOREIGN KEY (topic_id) REFERENCES topics(id)
);

CREATE TABLE included_indexed_posts (
    id SERIAL PRIMARY KEY,
    topic_id INTEGER,
    CONSTRAINT fk_included_indexed_posts_topic FOREIGN KEY (topic_id) REFERENCES topics(id)
);

CREATE TABLE opclass_indexed_codes (
    id SERIAL PRIMARY KEY,
    code TEXT,
    CONSTRAINT fk_opclass_indexed_codes_code FOREIGN KEY (code) REFERENCES codes(code)
);

CREATE TABLE collated_indexed_codes (
    id SERIAL PRIMARY KEY,
    code TEXT,
    CONSTRAINT fk_collated_indexed_codes_code FOREIGN KEY (code) REFERENCES codes(code)
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE subjects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER,
    subject_type VARCHAR(255)
);

CREATE INDEX index_posts_on_user_id ON posts(user_id, topic_id);
CREATE INDEX index_expression_indexed_posts_on_topic_id_expression ON expression_indexed_posts((topic_id::text));
CREATE INDEX index_partial_indexed_posts_on_topic_id ON partial_indexed_posts(topic_id) WHERE id > 0;
CREATE INDEX index_sorted_indexed_posts_on_topic_id ON sorted_indexed_posts(topic_id DESC NULLS LAST);
CREATE INDEX index_included_indexed_posts_on_topic_id ON included_indexed_posts(topic_id) INCLUDE (id);
CREATE INDEX index_opclass_indexed_codes_on_code ON opclass_indexed_codes(code text_pattern_ops);
CREATE INDEX index_collated_indexed_codes_on_code ON collated_indexed_codes(code COLLATE "C");

-- Advanced index forms used to verify catalog-based index metadata parsing.
CREATE INDEX index_users_on_company_id_desc ON users(company_id DESC NULLS LAST);
CREATE INDEX index_users_on_lower_email ON users((lower(email)));
CREATE INDEX index_users_on_email_partial ON users(email) WHERE customer_id IS NOT NULL;
CREATE INDEX index_users_on_email_pattern ON users(email text_pattern_ops);
CREATE INDEX index_posts_on_external_id_desc ON posts(external_id DESC NULLS LAST);
CREATE INDEX index_posts_on_user_id_desc_and_title_pattern ON posts(user_id DESC, title COLLATE "C" text_pattern_ops);
CREATE INDEX index_users_on_email_collate_c ON users(email COLLATE "C");
CREATE INDEX index_users_on_email_include_customer_id ON users(email) INCLUDE (customer_id);
SQL

    RubyPgExtras.connection.exec(DB_SCHEMA)
    RubyPgExtras.connection.exec("CREATE EXTENSION IF NOT EXISTS pg_stat_statements;")
    RubyPgExtras.connection.exec("CREATE EXTENSION IF NOT EXISTS pg_buffercache;")
    RubyPgExtras.connection.exec("CREATE EXTENSION IF NOT EXISTS sslinfo;")
  end
end
