# frozen_string_literal: true

require "spec_helper"

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
            { "table" => "public.channels", "index" => "index_channels_on_slack_id", "index_size" => "56 MB", "index_scans" => 7 },
          ]
        }

        expect(RubyPgExtras).to receive(:null_indexes) {
          [
            { "oid" => 123, "index" => "index_plans_on_payer_id", "index_size" => "16 MB", "unique" => true, "null_frac" => "00.00%", "expected_saving" => "0 kb" },
            { "oid" => 321, "index" => "index_feedbacks_on_target_id", "index_size" => "80 kB", "unique" => true, "null_frac" => "97.00%", "expected_saving" => "77 kb" },
            { "oid" => 231, "index" => "index_channels_on_slack_id", "index_size" => "56 MB", "unique" => true, "null_frac" => "49.99%", "expected_saving" => "28 MB" },
          ]
        }

        expect(RubyPgExtras).to receive(:bloat) {
          [
            { "type" => "table", "schemaname" => "public", "object_name" => "bloated_table_1", "bloat" => 8, "waste" => "0 kb" },
            { "type" => "table", "schemaname" => "public", "object_name" => "bloated_table_2", "bloat" => 8, "waste" => "77 kb" },
            { "type" => "schemaname", "public" => "index_channels_on_slack_id", "object_name" => "bloated_index", "bloat" => 11, "waste" => "28 MB" },
          ]
        }

        expect(RubyPgExtras).to receive(:duplicate_indexes) {
          [
            { "size" => "128 kb", "idx1" => "users_pkey", "idx2" => "index_users_id" },
          ]
        }

        expect(RubyPgExtras).to receive(:outliers) {
          [
            { "query" => "SELECT * FROM users WHERE users.age > 20 AND users.height > 160", "exec_time" => "154:39:26.431466", "prop_exec_time" => "72.2%", "ncalls" => "34,211,877", "sync_io_time" => "00:34:19.784318" },
          ]
        }

        expect(RubyPgExtras).to receive(:missing_fk_constraints) {
          [
            { table: "users", column_name: "company_id" },
            { table: "posts", column_name: "topic_id" },
          ]
        }

        expect(RubyPgExtras).to receive(:missing_fk_indexes) {
          [
            { table: "users", column_name: "company_id" },
            { table: "posts", column_name: "topic_id" },
          ]
        }

        expect(RubyPgExtras)
          .to receive(:update_stats)
          .with(in_format: :hash)
          .twice
          .and_return([])
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

  describe "#new_page_updates" do
    let(:diagnose_data) { described_class.new }

    it "reports tables exceeding the update sample and new-page thresholds" do
      allow(RubyPgExtras).to receive(:update_stats).with(in_format: :hash).and_return(
        [
          {
            "table" => "orders",
            "fillfactor" => "100",
            "total_updates" => "10000",
            "new_page_updates" => "2500",
            "new_page_pct" => "25.00",
            "hot_given_same_page_pct" => "90.00",
          },
          {
            "table" => "users",
            "fillfactor" => "80",
            "total_updates" => "9999",
            "new_page_updates" => "3000",
            "new_page_pct" => "30.00",
            "hot_given_same_page_pct" => "95.00",
          },
        ],
      )

      result = diagnose_data.send(:new_page_updates)

      expect(result).to eq(
        ok: false,
        message: <<~MESSAGE.strip,
          High new-page update ratios detected:

          'orders':
            new-page updates: 25.00% (2500 of 10000)
            HOT among same-page updates: 90.00%
            fillfactor: 100

          A high new-page ratio means many successor tuple versions were placed on another heap page and therefore could not be HOT. This commonly indicates insufficient reusable space on the original page. `n_tup_newpage_upd` records that placement directly; it does not identify the underlying reason or whether the update would otherwise have been HOT-eligible. Investigate page-space pressure, row growth, long-lived transactions, large update batches, and whether a lower table fillfactor is appropriate.

          The HOT-among-same-page percentage provides additional context: a low value suggests indexed-column changes are preventing HOT on updates that did stay on the same page, so changing fillfactor alone may not resolve the issue.

          These counters are cumulative; compare their deltas before and after a change.
        MESSAGE
      )
    end

    it "does not report tables below either threshold" do
      allow(RubyPgExtras).to receive(:update_stats).with(in_format: :hash).and_return(
        [
          {
            "table" => "orders",
            "total_updates" => "10000",
            "new_page_pct" => "19.99",
          },
          {
            "table" => "users",
            "total_updates" => "9999",
            "new_page_pct" => "25.00",
          },
        ],
      )

      expect(diagnose_data.send(:new_page_updates)).to eq(
        ok: true,
        message: "No tables with a high new-page update ratio detected.",
      )
    end

    it "allows overriding the thresholds with environment variables" do
      allow(RubyPgExtras).to receive(:update_stats).with(in_format: :hash).and_return(
        [
          {
            "table" => "orders",
            "fillfactor" => "100",
            "total_updates" => "500",
            "new_page_updates" => "75",
            "new_page_pct" => "15.00",
            "hot_given_same_page_pct" => "90.00",
          },
        ],
      )
      original_max_percent = ENV["PG_EXTRAS_NEW_PAGE_UPDATES_MAX_PERCENT"]
      original_min_sample = ENV["PG_EXTRAS_NEW_PAGE_UPDATES_MIN_SAMPLE"]
      ENV["PG_EXTRAS_NEW_PAGE_UPDATES_MAX_PERCENT"] = "15"
      ENV["PG_EXTRAS_NEW_PAGE_UPDATES_MIN_SAMPLE"] = "500"

      expect(diagnose_data.send(:new_page_updates).fetch(:ok)).to eq(false)
    ensure
      ENV["PG_EXTRAS_NEW_PAGE_UPDATES_MAX_PERCENT"] = original_max_percent
      ENV["PG_EXTRAS_NEW_PAGE_UPDATES_MIN_SAMPLE"] = original_min_sample
    end

    it "skips the check when update_stats returns the legacy breakdown" do
      allow(RubyPgExtras).to receive(:update_stats).with(in_format: :hash).and_return(
        [
          {
            "table" => "orders",
            "total_updates" => "10000",
            "hot_updates" => "5000",
            "hot_pct" => "50.00",
          },
        ],
      )

      expect(diagnose_data.send(:new_page_updates)).to eq(
        ok: true,
        message: "New-page update analysis requires PostgreSQL 16 or newer.",
      )
    end
  end

  describe "#low_hot_same_page" do
    let(:diagnose_data) { described_class.new }

    it "reports tables below the HOT-among-same-page threshold" do
      allow(RubyPgExtras).to receive(:update_stats).with(in_format: :hash).and_return(
        [
          {
            "table" => "sessions",
            "fillfactor" => "100",
            "total_updates" => "10000",
            "same_page_pct" => "95.61",
            "new_page_pct" => "4.39",
            "hot_given_same_page_pct" => "0.0",
          },
          {
            "table" => "orders",
            "fillfactor" => "80",
            "total_updates" => "10000",
            "same_page_pct" => "90.00",
            "new_page_pct" => "10.00",
            "hot_given_same_page_pct" => "10.00",
          },
          {
            "table" => "users",
            "fillfactor" => "100",
            "total_updates" => "9999",
            "same_page_pct" => "99.00",
            "new_page_pct" => "1.00",
            "hot_given_same_page_pct" => "0.0",
          },
        ],
      )

      result = diagnose_data.send(:low_hot_same_page)

      expect(result).to eq(
        ok: false,
        message: <<~MESSAGE.strip,
          Low HOT-among-same-page update ratios detected:

          'sessions':
            HOT among same-page updates: 0.0%
            same-page updates: 95.61%
            new-page updates: 4.39%
            fillfactor: 100

          A low HOT-among-same-page ratio means updates that stayed on the original heap page still could not be HOT. That usually means those updates modified indexed columns. Review which columns your application updates and which indexes cover them; removing or adjusting indexes on frequently updated columns (or avoiding updating those columns) can restore HOT updates and reduce index and vacuum overhead.

          These counters are cumulative; compare their deltas before and after a change.
        MESSAGE
      )
    end

    it "does not report tables at or above the threshold" do
      allow(RubyPgExtras).to receive(:update_stats).with(in_format: :hash).and_return(
        [
          {
            "table" => "orders",
            "total_updates" => "10000",
            "hot_given_same_page_pct" => "10.00",
          },
          {
            "table" => "users",
            "total_updates" => "9999",
            "hot_given_same_page_pct" => "0.0",
          },
        ],
      )

      expect(diagnose_data.send(:low_hot_same_page)).to eq(
        ok: true,
        message: "No tables with a low HOT-among-same-page update ratio detected.",
      )
    end

    it "skips tables with a NULL HOT-among-same-page ratio" do
      allow(RubyPgExtras).to receive(:update_stats).with(in_format: :hash).and_return(
        [
          {
            "table" => "orders",
            "total_updates" => "10000",
            "hot_given_same_page_pct" => nil,
          },
        ],
      )

      expect(diagnose_data.send(:low_hot_same_page)).to eq(
        ok: true,
        message: "No tables with a low HOT-among-same-page update ratio detected.",
      )
    end

    it "allows overriding the thresholds with environment variables" do
      allow(RubyPgExtras).to receive(:update_stats).with(in_format: :hash).and_return(
        [
          {
            "table" => "sessions",
            "fillfactor" => "100",
            "total_updates" => "500",
            "same_page_pct" => "90.00",
            "new_page_pct" => "10.00",
            "hot_given_same_page_pct" => "4.00",
          },
        ],
      )
      original_min_percent = ENV["PG_EXTRAS_LOW_HOT_SAME_PAGE_MIN_PERCENT"]
      original_min_sample = ENV["PG_EXTRAS_LOW_HOT_SAME_PAGE_MIN_SAMPLE"]
      ENV["PG_EXTRAS_LOW_HOT_SAME_PAGE_MIN_PERCENT"] = "5"
      ENV["PG_EXTRAS_LOW_HOT_SAME_PAGE_MIN_SAMPLE"] = "500"

      expect(diagnose_data.send(:low_hot_same_page).fetch(:ok)).to eq(false)
    ensure
      ENV["PG_EXTRAS_LOW_HOT_SAME_PAGE_MIN_PERCENT"] = original_min_percent
      ENV["PG_EXTRAS_LOW_HOT_SAME_PAGE_MIN_SAMPLE"] = original_min_sample
    end

    it "skips the check when update_stats returns the legacy breakdown" do
      allow(RubyPgExtras).to receive(:update_stats).with(in_format: :hash).and_return(
        [
          {
            "table" => "orders",
            "total_updates" => "10000",
            "hot_updates" => "5000",
            "hot_pct" => "50.00",
          },
        ],
      )

      expect(diagnose_data.send(:low_hot_same_page)).to eq(
        ok: true,
        message: "HOT-among-same-page update analysis requires PostgreSQL 16 or newer.",
      )
    end
  end
end
