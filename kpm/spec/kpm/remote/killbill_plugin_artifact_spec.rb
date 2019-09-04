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
      info[:file_name].should be_nil

      files_in_dir = Dir[info[:file_path] + '/*']
      files_in_dir.size.should == 1
      files_in_dir[0].should == info[:file_path] + '/killbill-payment-test'

      File.read(info[:file_path] + '/killbill-payment-test/1.8.7/killbill.properties').should == "mainClass=PaymentTest::PaymentPlugin\nrequire=payment_test\npluginType=PAYMENT\n"

      info[:bundle_dir].should == info[:file_path] + '/killbill-payment-test/1.8.7'
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
      info[:file_name].should == "analytics-plugin-#{info[:version]}.jar"
      info[:size].should == File.size(info[:file_path])

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
      info[:file_name].should be_nil

      check_yaml_for_resolved_latest_version(sha1_file, 'org.kill-bill.billing.plugin.ruby:logging-plugin:tar.gz', '3.0.0')
    end
  end

  it 'should be able to list versions' do
    versions = KPM::KillbillPluginArtifact.versions

    versions[:java].should_not be_nil
    versions[:java]['analytics-plugin'].should_not be_nil
    logging_plugin_versions = versions[:java]['analytics-plugin'].to_a
    logging_plugin_versions.size.should >= 3
    logging_plugin_versions[0].should == '0.6.0'
    logging_plugin_versions[1].should == '0.7.0'
    logging_plugin_versions[2].should == '0.7.1'

    versions[:ruby].should_not be_nil
    versions[:ruby]['logging-plugin'].should_not be_nil
    logging_plugin_versions = versions[:ruby]['logging-plugin'].to_a
    logging_plugin_versions.size.should >= 1
    logging_plugin_versions[0].should == '1.7.0'
  end

  private

  # We verify that 'LATEST' version has been correctly translated into the yml file
  # (we can't check against actual version because as we keep releasing those increment,
  # so the best we can do it check this is *not* LATEST and greater than current version at the time the test was written )
  def check_yaml_for_resolved_latest_version(sha1_file, key_prefix, minimum_version)

    sha1_checker = KPM::Sha1Checker.from_file(sha1_file)

    keys = sha1_checker.all_sha1.keys.select { |k| k.start_with? key_prefix}
    keys.size.should == 1

    parts = keys[0].split(':')
    parts.size.should == 4
    parts[3].should_not == 'LATEST'
    parts[3].should  >= minimum_version
  end
end
