require 'spec_helper'

describe KPM::BaseArtifact do

  before(:all) do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  it 'should be able to download and verify regular artifacts' do
    Dir.mktmpdir do |dir|
      test_download dir, 'foo-oss.pom.xml'
      # Verify we still don't skip the second time (sha1_file is null)
      test_download dir, 'foo-oss.pom.xml', false
      # Verify the download happens when we set force_download
      test_download dir, 'foo-oss.pom.xml', false, true
    end

    Dir.mktmpdir do |dir|
      test_download dir, nil
      # Verify we still don't skip the second time (sha1_file is null)
      test_download dir, nil, false
      # Verify the download happens when we set force_download
      test_download dir, nil, false, true
    end
  end

  it 'should be able to download and verify generic .tar.gz artifacts' do
    # The artifact is not small unfortunately (23.7M)
    group_id    = 'org.kill-bill.billing'
    artifact_id = 'killbill-osgi-bundles-defaultbundles'
    packaging   = 'tar.gz'
    classifier  = nil
    version     = '0.11.3'

    Dir.mktmpdir do |dir|
      info = KPM::BaseArtifact.pull(@logger, group_id, artifact_id, packaging, classifier, version, dir)
      info[:file_name].should be_nil

      files_in_dir = Dir[info[:file_path] + '/*']
      files_in_dir.size.should == 20

      File.file?(info[:file_path] + '/killbill-osgi-bundles-jruby-0.11.3.jar').should be_true

      info[:bundle_dir].should == info[:file_path]
    end
  end


  def test_download(dir, filename=nil, verify_is_skipped=false, force_download=false)
    path = filename.nil? ? dir : dir + '/' + filename

    info = KPM::BaseArtifact.pull(@logger, 'org.kill-bill.billing', 'killbill-oss-parent', 'pom', nil, 'LATEST', path, nil, force_download, true, {}, true)
    info[:file_name].should == (filename.nil? ? "killbill-oss-parent-#{info[:version]}.pom" : filename)
    info[:skipped].should == verify_is_skipped
    if !info[:skipped]
      info[:size].should == File.size(info[:file_path])
    end
  end
end
