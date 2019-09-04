# frozen_string_literal: true

require 'spec_helper'

describe KPM::BaseArtifact do
  before(:all) do
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  it 'should install from the filesystem' do
    file_path = File.join(File.dirname(__FILE__), 'sha1_test.yml')

    Dir.mktmpdir do |dir|
      info = KPM::BaseArtifact.pull_from_fs(@logger, file_path, dir)

      info[:skipped].should be_false
      info[:is_tgz].should be_false
      info[:repository_path].should == file_path
      info[:dir_name].should == dir
      info[:bundle_dir].should == dir
      info[:file_name].should == 'sha1_test.yml'

      files_in_dir = Dir[dir + '/*']
      files_in_dir.size.should == 1
      files_in_dir[0].should == info[:file_path]
    end
  end

  it 'should build the fs info' do
    # Kill Bill
    check_fs_info('/opt/tomcat/webapps/ROOT.war',
                  '/path/to/killbill.war',
                  false,
                  '1.2.3',
                  '/opt/tomcat/webapps',
                  'ROOT.war',
                  '/opt/tomcat/webapps/ROOT.war')

    # Default bundles
    check_fs_info('/var/tmp/bundles/platform',
                  '/path/to/bundles.tar.gz',
                  true,
                  '1.2.3',
                  '/var/tmp/bundles/platform',
                  nil,
                  '/var/tmp/bundles/platform')

    # Java plugin
    check_fs_info('/var/tmp/bundles/plugins/java/analytics-plugin/1.2.3',
                  '/path/to/analytics.jar',
                  false,
                  '1.2.3',
                  '/var/tmp/bundles/plugins/java/analytics-plugin/1.2.3',
                  'analytics.jar',
                  '/var/tmp/bundles/plugins/java/analytics-plugin/1.2.3/analytics.jar')
    check_fs_info('/var/tmp/bundles/plugins/java/analytics-plugin/LATEST',
                  '/path/to/analytics.jar',
                  false,
                  '1.2.3',
                  '/var/tmp/bundles/plugins/java/analytics-plugin/1.2.3',
                  'analytics.jar',
                  '/var/tmp/bundles/plugins/java/analytics-plugin/1.2.3/analytics.jar')

    # Ruby plugin
    check_fs_info('/var/tmp/bundles/plugins/ruby',
                  '/path/to/stripe.tar.gz',
                  true,
                  '1.2.3',
                  '/var/tmp/bundles/plugins/ruby',
                  nil,
                  '/var/tmp/bundles/plugins/ruby')
  end

  private

  def check_fs_info(specified_destination_path, repository_path, is_tgz, version, expected_dir_name, expected_file_name, expected_file_path)
    info = {
      repository_path: repository_path,
      is_tgz: is_tgz,
      version: version
    }

    KPM::BaseArtifact.send('populate_fs_info', info, specified_destination_path)

    info[:repository_path].should == repository_path
    info[:is_tgz].should == is_tgz
    info[:version].should == version
    info[:dir_name].should == expected_dir_name
    info[:file_name].should == expected_file_name
    info[:file_path].should == expected_file_path
  end
end
