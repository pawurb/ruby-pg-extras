# frozen_string_literal: true

require 'spec_helper'

describe RubyPgExtras::TableInfo do
  subject(:result) do
    RubyPgExtras::TableInfo.call
  end

  describe "call" do
    context "stubbed cases" do
      before do
        expect(RubyPgExtras).to receive(:tables) {
          [
            { "schemaname" => "public", "tablename" => "users" },
            { "schemaname" => "public", "tablename" => "teams" }
          ]
        }

        expect(RubyPgExtras).to receive(:table_size) {
          [
            { "name" => "teams", "size" => "25 MB" },
            {"name" => "users", "size" => "250 MB"},
          ]
        }

        expect(RubyPgExtras).to receive(:index_cache_hit) {
          [
            { "name" => "teams", "ratio" => "0.98" },
            { "name" => "users", "ratio" => "0.999" },
          ]
        }

        expect(RubyPgExtras).to receive(:table_cache_hit) {
          [
            { "name" => "teams", "ratio" => "0.88" },
            { "name" => "users", "ratio" => "0.899" },
          ]
        }

        expect(RubyPgExtras).to receive(:records_rank) {
          [
            { "name" => "teams", "estimated_count" => "358" },
            { "name" => "users", "estimated_count" => "8973" },
          ]
        }

        expect(RubyPgExtras).to receive(:seq_scans) {
          [
            { "name" => "teams", "count" => "0" },
            { "name" => "users", "count" => "409328" },
          ]
        }

        expect(RubyPgExtras).to receive(:table_index_scans) {
          [
            { "name" => "teams", "count" => "8579" },
            { "name" => "users", "count" => "0" },
          ]
        }
      end

      it "works" do
        expect {
          RubyPgExtras::TableInfoPrint.call(result)
        }.not_to raise_error
      end
    end

    context "real data" do
      it "works" do
        expect {
          RubyPgExtras::TableInfoPrint.call(result)
        }.not_to raise_error
      end
    end
  end
end
