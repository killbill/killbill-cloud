require 'spec_helper'

describe KPM::Sha1Checker do

  before(:all) do
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    tmp_destination_dir = Dir.tmpdir()
    init_config = File.join(File.dirname(__FILE__), 'sha1_test.yml')
    FileUtils.copy(init_config, tmp_destination_dir)
    @tmp_config = File.join(tmp_destination_dir, 'sha1_test.yml')
    @sha1_checker = KPM::Sha1Checker.from_file(@tmp_config)
  end

  it 'should find matching sha1' do
    existing = @sha1_checker.sha1('killbill-plugin-match-1.0.0.tar.gz')
    existing.should_not be_nil
    existing.should == 'fce068c3fd5f95646ce0d09852f43ff67f06f0b9'
  end

  it 'should NOT find sha1' do
    existing = @sha1_checker.sha1('killbill-plugin-nomatch-1.0.0.tar.gz')
    existing.should_not be_nil
    existing.should_not == 'fce068c3fd5f95646ce0d09852f43ff67f06f0b9'
  end

  it 'should NOT find matching sha1' do
    existing = @sha1_checker.sha1('killbill-plugin-foo-1.0.0.tar.gz')
    existing.should be_nil
  end

  it 'should add an entry and find them all' do
    @sha1_checker.add_or_modify_entry!('killbill-plugin-new-1.1.0.0.tar.gz', 'abc068c3fd5f95646ce0d09852f43ff67f06f111')

    existing = @sha1_checker.sha1('killbill-plugin-match-1.0.0.tar.gz')
    existing.should_not be_nil
    existing.should == 'fce068c3fd5f95646ce0d09852f43ff67f06f0b9'

    existing = @sha1_checker.sha1('killbill-plugin-new-1.1.0.0.tar.gz')
    existing.should_not be_nil
    existing.should == 'abc068c3fd5f95646ce0d09852f43ff67f06f111'


    existing = @sha1_checker.sha1('killbill-plugin-other-1.0.0.tar.gz')
    existing.should_not be_nil
    existing.should == 'bbb068c3fd5f95646ce0d09852f43ff67f06fccc'
  end

  it 'should add allow to modify an entry and find them all' do

    existing = @sha1_checker.sha1('killbill-plugin-match-1.0.0.tar.gz')
    existing.should_not be_nil
    existing.should == 'fce068c3fd5f95646ce0d09852f43ff67f06f0b9'

    @sha1_checker.add_or_modify_entry!('killbill-plugin-match-1.0.0.tar.gz', 'dde068c3fd5f95646ce0d09852f43ff67f06f0aa')


    existing = @sha1_checker.sha1('killbill-plugin-match-1.0.0.tar.gz')
    existing.should_not be_nil
    existing.should == 'dde068c3fd5f95646ce0d09852f43ff67f06f0aa'

    existing = @sha1_checker.sha1('killbill-plugin-other-1.0.0.tar.gz')
    existing.should_not be_nil
    existing.should == 'bbb068c3fd5f95646ce0d09852f43ff67f06fccc'
  end

  it 'should work with empty config' do

    tmp_destination_dir = Dir.tmpdir()
    empty_config = File.join(tmp_destination_dir, 'sha1_test.yml')
    if File.exists?(empty_config)
      # Just to be sure
      File.delete(empty_config)
    end
    @sha1_checker = KPM::Sha1Checker.from_file(empty_config)

    @sha1_checker.add_or_modify_entry!('killbill-plugin-new-1.1.0.0.tar.gz', 'abc068c3fd5f95646ce0d09852f43ff67f06f111')
    existing = @sha1_checker.sha1('killbill-plugin-new-1.1.0.0.tar.gz')
    existing.should_not be_nil
    existing.should == 'abc068c3fd5f95646ce0d09852f43ff67f06f111'
  end
end
