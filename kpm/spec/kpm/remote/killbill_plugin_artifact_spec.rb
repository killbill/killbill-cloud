# frozen_string_literal: true

require 'spec_helper'

describe KPM::KillbillPluginArtifact do
  before(:all) do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  # This test makes sure the top level directory is correctly verify_is_skipped
  it 'should be able to download and verify .tar.gz ruby artifacts' do
    # Use the payment-test-plugin as a test, as it is fairly small (2.5M)
    group_id    = 'org.kill-bill.billing.plugin.ruby'
    artifact_id = 'payment-test-plugin'
    packaging   = 'tar.gz'
    classifier  = nil
    version     = '1.8.7'
    plugin_name = 'killbill-payment-test'

    Dir.mktmpdir do |dir|
      info = KPM::KillbillPluginArtifact.pull(@logger, group_id, artifact_id, packaging, classifier, version, plugin_name, dir)
      expect(info[:file_name]).to be_nil

      files_in_dir = Dir[info[:file_path] + '/*']
      expect(files_in_dir.size).to eq 1
      expect(files_in_dir[0]).to eq info[:file_path] + '/killbill-payment-test'

      expect(File.read(info[:file_path] + '/killbill-payment-test/1.8.7/killbill.properties')).to eq "mainClass=PaymentTest::PaymentPlugin\nrequire=payment_test\npluginType=PAYMENT\n"

      expect(info[:bundle_dir]).to eq info[:file_path] + '/killbill-payment-test/1.8.7'
    end
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

    Dir.mktmpdir do |dir|
      sha1_file = dir + '/sha1.yml'
      info = KPM::KillbillPluginArtifact.pull(@logger,
                                              KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID,
                                              'logging-plugin',
                                              KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING,
                                              KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER,
                                              'LATEST',
                                              'killbill-analytics',
                                              dir,
                                              sha1_file)

      # No file name - since we untar'ed it
      expect(info[:file_name]).to be_nil

      check_yaml_for_resolved_latest_version(sha1_file, 'org.kill-bill.billing.plugin.ruby:logging-plugin:tar.gz', '3.0.0')
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

    expect(versions[:ruby]).not_to be_nil
    expect(versions[:ruby]['logging-plugin']).not_to be_nil
    logging_plugin_versions = versions[:ruby]['logging-plugin'].to_a
    expect(logging_plugin_versions.size).to be >= 1
    expect(logging_plugin_versions[0]).to eq '1.7.0'
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
