# frozen_string_literal: true

require 'spec_helper'

describe KPM::Migrations, skip_me_if_nil: ENV['TOKEN'].nil? do
  context 'plugins' do
    it 'should be able to find migrations for a java plugin' do
      migrations = KPM::Migrations.new('analytics-plugin-3.0.2', nil, 'killbill/killbill-analytics-plugin', ENV['TOKEN']).migrations
      # No migration yet
      expect(migrations.size).to eq 0
    end

    it 'should be able to find migrations for a ruby plugin' do
      migrations = KPM::Migrations.new('master', nil, 'killbill/killbill-cybersource-plugin', ENV['TOKEN']).migrations
      # No migration yet
      expect(migrations.size).to eq 1
    end
  end

  context 'killbill' do
    it 'should be able to find migrations between two versions' do
      migrations = KPM::Migrations.new('killbill-0.16.3', 'killbill-0.16.4', 'killbill/killbill', ENV['TOKEN']).migrations

      expect(migrations.size).to eq 1
      expect(migrations.first[:name]).to eq 'V20160324060345__revisit_payment_methods_indexes_509.sql'
      expect(migrations.first[:sql]).to eq "drop index payment_methods_active_accnt on payment_methods;\n"

      expect(KPM::Migrations.new('master', 'master', 'killbill/killbill', ENV['TOKEN']).migrations.size).to eq 0
    end

    it 'should be able to find migrations for a given version' do
      migrations = KPM::Migrations.new('killbill-0.16.4', nil, 'killbill/killbill', ENV['TOKEN']).migrations

      expect(migrations.size).to eq 1
      expect(migrations.first[:name]).to eq 'V20160324060345__revisit_payment_methods_indexes_509.sql'
      expect(migrations.first[:sql]).to eq "drop index payment_methods_active_accnt on payment_methods;\n"
    end
  end
end
