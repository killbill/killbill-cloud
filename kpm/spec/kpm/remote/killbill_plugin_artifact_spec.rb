require 'spec_helper'

describe KPM::KillbillPluginArtifact do

  before(:all) do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  it 'should be able to download and verify artifacts' do
    Dir.mktmpdir do |dir|
      info = KPM::KillbillPluginArtifact.pull(@logger,
                                              KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID,
                                              'analytics-plugin',
                                              KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING,
                                              KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER,
                                              'LATEST',
                                              dir)
      info[:file_name].should == "analytics-plugin-#{info[:version]}.jar"
      info[:size].should == File.size(info[:file_path])
    end

    Dir.mktmpdir do |dir|
      info = KPM::KillbillPluginArtifact.pull(@logger,
                                              KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID,
                                              'logging-plugin',
                                              KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING,
                                              KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER,
                                              'LATEST',
                                              dir)

      # No file name - since we untar'ed it
      info[:file_name].should be_nil
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
end
