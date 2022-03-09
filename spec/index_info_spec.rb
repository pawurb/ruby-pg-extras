# frozen_string_literal: true

require 'spec_helper'

describe RubyPgExtras::IndexInfo do
  subject(:result) do
    RubyPgExtras::IndexInfo.call
  end

  describe "call" do
    context "stubbed cases" do
      before do
        expect(RubyPgExtras).to receive(:indexes) {
          [
            { "schemaname" => "public", "indexname" => "index_users_on_api_auth_token", "tablename" => "users", "columns" => "api_auth_token, column2" },
            {"schemaname" => "public", "indexname" => "index_teams_on_slack_id", "tablename" => "teams", "columns" => "slack_id" },
          ]
        }

        expect(RubyPgExtras).to receive(:index_size) {
          [
            { "name" => "index_users_on_api_auth_token", "size" => "1744 kB" },
            {"name" => "index_teams_on_slack_id", "size" => "500 kB"},
          ]
        }

        expect(RubyPgExtras).to receive(:null_indexes) {
          [
            { "oid" => 16803, "index" => "index_users_on_api_auth_token", "index_size" => "1744 kB", "unique"=>true, "indexed_column" => "api_auth_token", "null_frac" => "25.00%", "expected_saving" => "300 kB" }
          ]
        }

        expect(RubyPgExtras).to receive(:index_scans) {
          [
            { "schemaname" => "public", "table" => "users", "index" => "index_users_on_api_auth_token", "index_size" => "1744 kB", "index_scans"=> 0 },
            { "schemaname" => "public", "table" => "teams", "index" => "index_teams_on_slack_id", "index_size" => "500 kB", "index_scans"=> 0 }
          ]
        }
      end

      it "works" do
        expect {
          RubyPgExtras::IndexInfoPrint.call(result)
        }.not_to raise_error
      end
    end

    context "real data" do
      it "works" do
        expect {
          RubyPgExtras::IndexInfoPrint.call(result)
        }.not_to raise_error
      end
    end
  end
end
