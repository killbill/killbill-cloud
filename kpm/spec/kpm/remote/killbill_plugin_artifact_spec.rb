# frozen_string_literal: true

require 'spec_helper'

describe KPM::KillbillPluginArtifact do
  before(:all) do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  it 'should be able to download and verify artifacts' do
    Dir.mktmpdir do |dir|
      sha1_file = dir + '/sha1.yml'
      info = KPM::KillbillPluginArtifact.pull(@logger,
                                              KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID,
                                              'analytics-plugin',
                                              KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING,
                                              KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER,
                                              'LATEST',
                                              'killbill-analytics',
                                              dir,
                                              sha1_file)
      expect(info[:file_name]).to eq "analytics-plugin-#{info[:version]}.jar"
      expect(info[:size]).to eq File.size(info[:file_path])

      check_yaml_for_resolved_latest_version(sha1_file, 'org.kill-bill.billing.plugin.java:analytics-plugin:jar', '3.0.0')
    end
  end

  it 'should be able to list versions' do
    versions = KPM::KillbillPluginArtifact.versions

    expect(versions[:java]).not_to be_nil
    expect(versions[:java]['analytics-plugin']).not_to be_nil
    logging_plugin_versions = versions[:java]['analytics-plugin'].to_a
    expect(logging_plugin_versions.size).to be >= 3
    expect(logging_plugin_versions[0]).to eq '0.6.0'
    expect(logging_plugin_versions[1]).to eq '0.7.0'
    expect(logging_plugin_versions[2]).to eq '0.7.1'
  end

  private

  # We verify that 'LATEST' version has been correctly translated into the yml file
  # (we can't check against actual version because as we keep releasing those increment,
  # so the best we can do it check this is *not* LATEST and greater than current version at the time the test was written )
  def check_yaml_for_resolved_latest_version(sha1_file, key_prefix, minimum_version)
    sha1_checker = KPM::Sha1Checker.from_file(sha1_file)

    keys = sha1_checker.all_sha1.keys.select { |k| k.start_with? key_prefix }
    expect(keys.size).to eq 1

    parts = keys[0].split(':')
    expect(parts.size).to eq 4
    expect(parts[3]).not_to eq 'LATEST'
    expect(parts[3]).to be >= minimum_version
  end
end
