# frozen_string_literal: true

require "spec_helper"

describe RubyPgExtras::DiagnosePrint do
  subject(:print_result) do
    RubyPgExtras::DiagnosePrint.call(data)
  end

  let(:data) do
    [
      {
        :check_name => :table_cache_hit,
        :ok => false,
        :message => "Table hit ratio too low: 0.906977.",
      },
      {
        :check_name => :index_cache_hit,
        :ok => false,
        :message => "Index hit ratio is too low: 0.818182.",
      },
      {
        :check_name => :ssl_used,
        :ok => true,
        :message => "Database client is using a secure SSL connection.",
      },
    ]
  end

  describe "call" do
    it "works" do
      expect {
        print_result
      }.not_to raise_error
    end
  end
end
