# frozen_string_literal: true

require 'spec_helper'

describe RubyPgExtras::DiagnoseData do
  subject(:result) do
    RubyPgExtras::DiagnoseData.call
  end

  describe "call" do
    context "stubbed cases" do
      before do
        expect(RubyPgExtras).to receive(:unused_indexes) {
          [
            { "table" => "public.plans", "index" => "index_plans_on_payer_id", "index_size" => "16 MB", "index_scans" => 0 },
            { "table" => "public.feedbacks", "index" => "index_feedbacks_on_target_id", "index_size" => "111180 bytes", "index_scans" => 1 },
            { "table" => "public.channels", "index" => "index_channels_on_slack_id", "index_size" => "56 MB", "index_scans" => 7}
          ]
        }

        expect(RubyPgExtras).to receive(:null_indexes) {
          [
            { "oid" => 123, "index" => "index_plans_on_payer_id", "index_size" => "16 MB", "unique" => true, "null_frac" => "00.00%", "expected_saving" => "0 kb" },
            { "oid" => 321, "index" => "index_feedbacks_on_target_id", "index_size" => "80 kB", "unique" => true, "null_frac" => "97.00%", "expected_saving" => "77 kb" },
            { "oid" => 231, "index" => "index_channels_on_slack_id", "index_size" => "56 MB", "unique" => true, "null_frac" => "49.99%", "expected_saving" => "28 MB" }
          ]
        }

        expect(RubyPgExtras).to receive(:bloat) {
          [
            { "type" => "table", "schemaname" => "public", "object_name" => "bloated_table_1", "bloat" => 8, "waste" => "0 kb" },
            { "type" => "table", "schemaname" => "public", "object_name" => "bloated_table_2", "bloat" => 8, "waste" => "77 kb" },
            { "type" => "schemaname", "public" => "index_channels_on_slack_id", "object_name" => "bloated_index", "bloat" => 11, "waste" => "28 MB" }
          ]
        }

        expect(RubyPgExtras).to receive(:duplicate_indexes) {
          [
            { "size" => "128 kb", "idx1" => "users_pkey", "idx2" => "index_users_id" }
          ]
        }

        expect(RubyPgExtras).to receive(:outliers) {
          [
            { "query" => "SELECT * FROM users WHERE users.age > 20 AND users.height > 160", "exec_time" => "154:39:26.431466", "prop_exec_time" => "72.2%", "ncalls" => "34,211,877", "sync_io_time" => "00:34:19.784318" }
          ]
        }
      end

      it "works" do
        expect {
          RubyPgExtras::DiagnosePrint.call(result)
        }.not_to raise_error
      end
    end

    context "real database data" do
      it "works" do
        expect {
          RubyPgExtras::DiagnosePrint.call(result)
        }.not_to raise_error
      end
    end
  end
end
