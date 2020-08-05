# frozen_string_literal: true

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

  it 'should be able to handle download errors' do
    nexus_down = { url: 'https://does.not.exist' }
    Dir.mktmpdir do |dir|
      sha1_file = "#{dir}/sha1.yml"
      test_download dir, 'foo-oss.pom.xml', false, false, sha1_file
      # Verify we skip the second time
      test_download dir, 'foo-oss.pom.xml', true, false, sha1_file
      # Verify the download is skipped gracefully when Nexus isn't reachable
      test_download dir, 'foo-oss.pom.xml', true, false, sha1_file, nexus_down
      # Verify the download fails when Nexus isn't reachable and force_download is set
      expect { test_download dir, 'foo-oss.pom.xml', nil, true, sha1_file, nexus_down }.to raise_exception(SocketError, /(Failed to open TCP connection to does.not.exist:443|getaddrinfo)/)
      # Verify the download fails when Nexus isn't reachable and the Nexus cache is empty
      expect(KPM::Sha1Checker.from_file(sha1_file).artifact_info('org.kill-bill.billing:killbill-oss-parent:pom:0.143.33')).to_not be_nil
      KPM::Sha1Checker.from_file(sha1_file).remove_entry!('org.kill-bill.billing:killbill-oss-parent:pom:0.143.33')
      expect(KPM::Sha1Checker.from_file(sha1_file).artifact_info('org.kill-bill.billing:killbill-oss-parent:pom:0.143.33')).to be_nil
      expect { test_download dir, 'foo-oss.pom.xml', nil, false, sha1_file, nexus_down }.to raise_exception(SocketError, /(Failed to open TCP connection to does.not.exist:443|getaddrinfo)/)
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
      expect(info[:file_name]).to be_nil

      files_in_dir = Dir[info[:file_path] + '/*']
      expect(files_in_dir.size).to eq 20

      expect(File.file?(info[:file_path] + '/killbill-osgi-bundles-jruby-0.11.3.jar')).to be_truthy

      expect(info[:bundle_dir]).to eq info[:file_path]
    end
  end

  it 'should be able to download and remove previous version artifacts' do
    group_id    = 'org.kill-bill.billing'
    artifact_id = 'killbill-platform-osgi-bundles-defaultbundles'
    packaging   = 'tar.gz'
    classifier  = nil
    version     = '0.36.2'

    second_bundle_version = '0.36.10'

    Dir.mktmpdir do |dir|
      first_take = KPM::BaseArtifact.pull(@logger, group_id, artifact_id, packaging, classifier, version, dir)
      expect(File.file?(first_take[:file_path] + '/killbill-platform-osgi-bundles-jruby-0.36.2.jar')).to be_truthy

      second_take = KPM::BaseArtifact.pull(@logger, group_id, artifact_id, packaging, classifier, second_bundle_version, dir)
      expect(File.file?(first_take[:file_path] + '/killbill-platform-osgi-bundles-jruby-0.36.2.jar')).to be_falsey
      expect(File.file?(second_take[:file_path] + '/killbill-platform-osgi-bundles-jruby-0.36.10.jar')).to be_truthy
    end
  end

  def test_download(dir, filename = nil, verify_is_skipped = false, force_download = false, sha1_file = nil, overrides = {})
    path = filename.nil? ? dir : dir + '/' + filename

    info = KPM::BaseArtifact.pull(@logger, 'org.kill-bill.billing', 'killbill-oss-parent', 'pom', nil, '0.143.33', path, sha1_file, force_download, true, overrides, true)
    expect(info[:file_name]).to eq(filename.nil? ? "killbill-oss-parent-#{info[:version]}.pom" : filename)
    expect(info[:skipped]).to eq verify_is_skipped
    expect(info[:size]).to eq File.size(info[:file_path]) unless info[:skipped]
  end
end
