# frozen_string_literal: true

require 'spec_helper'

describe KPM::KillbillPluginArtifact do
  before(:all) do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  it 'should be able to download and verify artifacts' do
    Dir.mktmpdir do |dir|
      info = KPM::KauiArtifact.pull(@logger,
                                    KPM::BaseArtifact::KAUI_GROUP_ID,
                                    KPM::BaseArtifact::KAUI_ARTIFACT_ID,
                                    KPM::BaseArtifact::KAUI_PACKAGING,
                                    KPM::BaseArtifact::KAUI_CLASSIFIER,
                                    'LATEST',
                                    dir)
      info[:file_name].should == "kaui-standalone-#{info[:version]}.war"
      info[:size].should == File.size(info[:file_path])
    end
  end

  it 'should be able to list versions' do
    versions = KPM::KauiArtifact.versions.to_a
    versions.size.should >= 2
    versions[0].should == '0.0.1'
    versions[1].should == '0.0.2'
  end
end
