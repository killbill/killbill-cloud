# frozen_string_literal: true

require 'spec_helper'

describe KPM::KillbillServerArtifact do
  before(:all) do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  # Takes about 7 minutes...
  it 'should be able to download and verify artifacts' do
    Dir.mktmpdir do |dir|
      info = KPM::KillbillServerArtifact.pull(@logger,
                                              KPM::BaseArtifact::KILLBILL_GROUP_ID,
                                              KPM::BaseArtifact::KILLBILL_ARTIFACT_ID,
                                              KPM::BaseArtifact::KILLBILL_PACKAGING,
                                              KPM::BaseArtifact::KILLBILL_CLASSIFIER,
                                              'LATEST',
                                              dir)
      expect(info[:file_name]).to eq "killbill-profiles-killbill-#{info[:version]}.war"
      expect(info[:size]).to eq File.size(info[:file_path])
    end
  end

  it 'should be able to list versions' do
    versions = KPM::KillbillServerArtifact.versions(KPM::BaseArtifact::KILLBILL_ARTIFACT_ID).to_a
    expect(versions.size).to be >= 2
    expect(versions[0]).to eq '0.11.10'
    expect(versions[1]).to eq '0.11.11'
  end

  it 'should get dependencies information' do
    nexus_down = { url: 'https://does.not.exist' }

    Dir.mktmpdir do |dir|
      sha1_file = "#{dir}/sha1.yml"
      info = KPM::KillbillServerArtifact.info('0.15.9', sha1_file)
      expect(info['killbill']).to eq '0.15.9'
      expect(info['killbill-oss-parent']).to eq '0.62'
      expect(info['killbill-api']).to eq '0.27'
      expect(info['killbill-plugin-api']).to eq '0.16'
      expect(info['killbill-commons']).to eq '0.10'
      expect(info['killbill-platform']).to eq '0.13'
      expect(KPM::Sha1Checker.from_file(sha1_file).killbill_info('0.15.9')).to eq info

      # Verify the download is skipped gracefully when Nexus isn't reachable
      KPM::KillbillServerArtifact.info('0.15.9', sha1_file, false, nil, nexus_down)

      # Verify the download fails when Nexus isn't reachable and force_download is set
      expect { KPM::KillbillServerArtifact.info('0.15.9', sha1_file, true, nil, nexus_down) }.to raise_exception(SocketError, /Failed to open TCP connection to does.not.exist:443/)

      # Verify the download fails when Nexus isn't reachable and the Nexus cache is empty
      KPM::Sha1Checker.from_file(sha1_file).cache_killbill_info('0.15.9', nil)
      expect { KPM::KillbillServerArtifact.info('0.15.9', sha1_file, false, nil, nexus_down) }.to raise_exception(SocketError, /Failed to open TCP connection to does.not.exist:443/)
    end
  end
end
