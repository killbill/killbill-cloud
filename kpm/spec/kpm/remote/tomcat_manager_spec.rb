# frozen_string_literal: true

require 'spec_helper'

describe KPM::TomcatManager do
  before(:all) do
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  it 'should be able to download and unpack tomcat' do
    Dir.mktmpdir do |dir|
      manager = KPM::TomcatManager.new(dir, @logger)

      tomcat_path = manager.download
      tomcat_path.should_not be_nil

      root_war_path = manager.setup
      root_war_path.should_not be_nil
    end
  end
end
