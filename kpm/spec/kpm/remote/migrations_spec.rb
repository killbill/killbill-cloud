# frozen_string_literal: true

require 'spec_helper'

describe KPM::Migrations, skip_me_if_nil: ENV['TOKEN'].nil? do
  context 'plugins' do
    it 'should be able to find migrations for a java plugin' do
      migrations = KPM::Migrations.new('analytics-plugin-3.0.2', nil, 'killbill/killbill-analytics-plugin', ENV['TOKEN']).migrations
      # No migration yet
      migrations.size.should == 0
    end

    it 'should be able to find migrations for a ruby plugin' do
      migrations = KPM::Migrations.new('master', nil, 'killbill/killbill-cybersource-plugin', ENV['TOKEN']).migrations
      # No migration yet
      migrations.size.should == 1
    end
  end

  context 'killbill' do
    it 'should be able to find migrations between two versions' do
      migrations = KPM::Migrations.new('killbill-0.16.3', 'killbill-0.16.4', 'killbill/killbill', ENV['TOKEN']).migrations

      migrations.size.should == 1
      migrations.first[:name].should == 'V20160324060345__revisit_payment_methods_indexes_509.sql'
      migrations.first[:sql].should == "drop index payment_methods_active_accnt on payment_methods;\n"

      KPM::Migrations.new('master', 'master', 'killbill/killbill', ENV['TOKEN']).migrations.size.should == 0
    end

    it 'should be able to find migrations for a given version' do
      migrations = KPM::Migrations.new('killbill-0.16.4', nil, 'killbill/killbill', ENV['TOKEN']).migrations

      migrations.size.should == 1
      migrations.first[:name].should == 'V20160324060345__revisit_payment_methods_indexes_509.sql'
      migrations.first[:sql].should == "drop index payment_methods_active_accnt on payment_methods;\n"
    end
  end
end
