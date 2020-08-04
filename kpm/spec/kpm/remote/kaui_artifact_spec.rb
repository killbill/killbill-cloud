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
      expect(info[:file_name]).to eq "kaui-standalone-#{info[:version]}.war"
      expect(info[:size]).to eq File.size(info[:file_path])
    end
  end

  it 'should be able to list versions' do
    versions = KPM::KauiArtifact.versions.to_a
    expect(versions.size).to be >= 2
    expect(versions[0]).to eq '0.0.1'
    expect(versions[1]).to eq '0.0.2'
  end
end
