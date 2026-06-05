# frozen_string_literal: true

require "spec_helper"

describe RubyPgExtras::IndexInfo do
  subject(:result) do
    RubyPgExtras::IndexInfo.call
  end

  describe "call" do
    context "stubbed cases" do
      before do
        expect(RubyPgExtras).to receive(:indexes) {
          [
            {
              "schemaname" => "public",
              "indexname" => "index_users_on_api_auth_token",
              "tablename" => "users",
              "columns" => "api_auth_token, column2",
              "columns_json" => '["api_auth_token","column2"]',
              "key_columns" => "api_auth_token, column2",
              "key_column_names" => '["api_auth_token","column2"]',
              "included_columns" => "",
              "included_columns_json" => "[]",
              "index_method" => "btree",
              "is_unique" => "f",
              "is_primary" => "f",
              "is_partial" => "f",
              "predicate" => nil,
            },
            {
              "schemaname" => "public",
              "indexname" => "index_teams_on_slack_id",
              "tablename" => "teams",
              "columns" => "slack_id",
              "columns_json" => '["slack_id"]',
              "key_columns" => "slack_id",
              "key_column_names" => '["slack_id"]',
              "included_columns" => "external_id",
              "included_columns_json" => '["external_id"]',
              "index_method" => "btree",
              "is_unique" => "t",
              "is_primary" => "f",
              "is_partial" => "t",
              "predicate" => "external_id IS NOT NULL",
            },
          ]
        }

        expect(RubyPgExtras).to receive(:index_size) {
          [
            { "name" => "index_users_on_api_auth_token", "size" => "1744 kB" },
            { "name" => "index_teams_on_slack_id", "size" => "500 kB" },
          ]
        }

        expect(RubyPgExtras).to receive(:null_indexes) {
          [
            { "oid" => 16803, "index" => "index_users_on_api_auth_token", "index_size" => "1744 kB", "unique" => true, "indexed_column" => "api_auth_token", "null_frac" => "25.00%", "expected_saving" => "300 kB" },
          ]
        }

        expect(RubyPgExtras).to receive(:index_scans) {
          [
            { "schemaname" => "public", "table" => "users", "index" => "index_users_on_api_auth_token", "index_size" => "1744 kB", "index_scans" => 0 },
            { "schemaname" => "public", "table" => "teams", "index" => "index_teams_on_slack_id", "index_size" => "500 kB", "index_scans" => 0 },
          ]
        }
      end

      it "works" do
        expect {
          RubyPgExtras::IndexInfoPrint.call(result)
        }.not_to raise_error
      end

      it "returns structured index metadata" do
        # The service keeps display columns and logical key columns as separate arrays.
        expect(result).to include(
          include(
            index_name: "index_teams_on_slack_id",
            columns: ["slack_id"],
            key_columns: ["slack_id"],
            included_columns: ["external_id"],
            index_method: "btree",
            unique: true,
            primary: false,
            partial: true,
            predicate: "external_id IS NOT NULL",
          )
        )
      end
    end

    context "real data" do
      it "works" do
        expect {
          RubyPgExtras::IndexInfoPrint.call(result)
        }.not_to raise_error
      end

      it "handles expression indexes without splitting on parentheses" do
        index = result.find { |el| el.fetch(:index_name) == "index_users_on_lower_email" }

        # Expression indexes can contain nested parentheses, so DDL string splitting is unsafe.
        expect(index.fetch(:columns).first).to include("lower")
      end

      it "keeps partial index predicates separate from columns" do
        index = result.find { |el| el.fetch(:index_name) == "index_users_on_email_partial" }

        # Partial index predicates describe row coverage and should not be mixed into columns.
        expect(index).to include(
          columns: ["email"],
          key_columns: ["email"],
          partial: true,
        )
        expect(index.fetch(:predicate)).to include("customer_id IS NOT NULL")
      end

      it "keeps operator classes in display columns and clean key column names" do
        index = result.find { |el| el.fetch(:index_name) == "index_users_on_email_pattern" }

        # Opclasses affect index behavior, but FK checks still need the plain column name.
        expect(index.fetch(:columns)).to eq(["email text_pattern_ops"])
        expect(index.fetch(:key_columns)).to eq(["email"])
      end

      it "keeps sort order in display columns and clean key column names" do
        index = result.find { |el| el.fetch(:index_name) == "index_posts_on_external_id_desc" }

        # Sort/null options are display metadata, not part of the logical column name.
        expect(index.fetch(:columns)).to eq(["external_id DESC NULLS LAST"])
        expect(index.fetch(:key_columns)).to eq(["external_id"])
      end

      it "keeps per-position options on composite indexes" do
        index = result.find { |el| el.fetch(:index_name) == "index_posts_on_user_id_desc_and_title_pattern" }

        # Each position can have distinct options, so the query must pair metadata by position.
        expect(index.fetch(:columns)).to eq(["user_id DESC NULLS FIRST", 'title COLLATE "C" text_pattern_ops'])
        expect(index.fetch(:key_columns)).to eq(["user_id", "title"])
      end

      it "keeps collations in display columns and clean key column names" do
        index = result.find { |el| el.fetch(:index_name) == "index_users_on_email_collate_c" }

        # Explicit non-default collations should remain visible in index_info output.
        expect(index.fetch(:columns).first).to include('COLLATE "C"')
        expect(index.fetch(:key_columns)).to eq(["email"])
      end

      it "keeps included columns separate from key columns" do
        index = result.find { |el| el.fetch(:index_name) == "index_users_on_email_include_customer_id" }

        # INCLUDE columns can support index-only scans but are not search key columns.
        expect(index).to include(
          columns: ["email"],
          key_columns: ["email"],
          included_columns: ["customer_id"],
        )
      end
    end
  end
end
