# frozen_string_literal: true

require 'spec_helper'

describe RubyPGExtras::DiagnosePrint do
  subject(:print_result) do
    RubyPGExtras::DiagnosePrint.call(data)
  end

  let(:data) do
    {
      :table_cache_hit =>  {
        :ok => false,
        :message => "Table hit ratio too low: 0.906977."
       },
      :index_cache_hit => {
        :ok => false,
        :message => "Index hit ratio is too low: 0.818182."
      },
      :ssl_used => {
        :ok => true,
        :message => "Database client is using a secure SSL connection."
      }
    }
  end

  describe "call" do
    it "works" do
      expect {
        print_result
      }.not_to raise_error
    end
  end
end
