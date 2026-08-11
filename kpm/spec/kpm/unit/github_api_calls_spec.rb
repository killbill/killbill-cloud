# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

describe KPM::NexusFacade::GithubApiCalls do
  let(:logger) do
    logger = ::Logger.new(STDOUT)
    logger.level = Logger::FATAL
    logger
  end
  let(:config) { { url: 'https://maven.pkg.github.com/myorg/my-repo', token: 'fake-token' } }
  let(:nexus_remote) { described_class.new(config, true, logger) }

  let(:snapshot_coordinates) { 'com.example:my-plugin:jar:2.0.1-SNAPSHOT' }
  let(:release_coordinates) { 'com.example:my-plugin:jar:1.0.0' }

  let(:snapshot_metadata_xml) do
    <<~XML
      <metadata>
        <groupId>com.example</groupId>
        <artifactId>my-plugin</artifactId>
        <version>2.0.1-SNAPSHOT</version>
        <versioning>
          <snapshot>
            <timestamp>20240520.203819</timestamp>
            <buildNumber>1</buildNumber>
          </snapshot>
          <snapshotVersions>
            <snapshotVersion>
              <extension>jar</extension>
              <value>2.0.1-20240520.203819-1</value>
              <updated>20240520203819</updated>
            </snapshotVersion>
            <snapshotVersion>
              <extension>pom</extension>
              <value>2.0.1-20240520.203819-1</value>
              <updated>20240520203819</updated>
            </snapshotVersion>
          </snapshotVersions>
          <lastUpdated>20240520203819</lastUpdated>
        </versioning>
      </metadata>
    XML
  end

  describe '#get_artifact_info_endpoint' do
    it 'returns version-level metadata URL for SNAPSHOT versions' do
      endpoint = nexus_remote.get_artifact_info_endpoint(snapshot_coordinates)
      expect(endpoint).to eq('/myorg/my-repo/com/example/my-plugin/2.0.1-SNAPSHOT/maven-metadata.xml')
    end

    it 'returns top-level metadata URL for release versions' do
      endpoint = nexus_remote.get_artifact_info_endpoint(release_coordinates)
      expect(endpoint).to eq('/myorg/my-repo/com/example/my-plugin/maven-metadata.xml')
    end
  end

  describe '#pull_artifact_endpoint' do
    context 'with a SNAPSHOT version' do
      before do
        allow(nexus_remote).to receive(:parent_get_artifact_info)
          .with(snapshot_coordinates)
          .and_return(snapshot_metadata_xml)
      end

      it 'uses SNAPSHOT directory with timestamped filename' do
        endpoint = nexus_remote.pull_artifact_endpoint(snapshot_coordinates)
        expect(endpoint).to eq('/myorg/my-repo/com/example/my-plugin/2.0.1-SNAPSHOT/my-plugin-2.0.1-20240520.203819-1.jar')
      end
    end

    context 'with a release version' do
      it 'uses the literal version' do
        endpoint = nexus_remote.pull_artifact_endpoint(release_coordinates)
        expect(endpoint).to eq('/myorg/my-repo/com/example/my-plugin/1.0.0/my-plugin-1.0.0.jar')
      end
    end

    context 'when metadata fetch fails' do
      before do
        allow(nexus_remote).to receive(:parent_get_artifact_info)
          .with(snapshot_coordinates)
          .and_raise(StandardError, 'connection failed')
      end

      it 'falls back to the literal SNAPSHOT version' do
        endpoint = nexus_remote.pull_artifact_endpoint(snapshot_coordinates)
        expect(endpoint).to eq('/myorg/my-repo/com/example/my-plugin/2.0.1-SNAPSHOT/my-plugin-2.0.1-SNAPSHOT.jar')
      end
    end
  end

  describe '#get_artifact_info' do
    let(:sha1_value) { 'abc123def456' }

    context 'with a SNAPSHOT version' do
      before do
        allow(nexus_remote).to receive(:parent_get_artifact_info)
          .with(snapshot_coordinates)
          .and_return(snapshot_metadata_xml)
        allow(nexus_remote).to receive(:get_response_with_retries)
          .and_return(sha1_value)
      end

      it 'reports the original SNAPSHOT version' do
        info = nexus_remote.get_artifact_info(snapshot_coordinates)
        doc = REXML::Document.new(info)
        expect(doc.elements['//version'].text).to eq('2.0.1-SNAPSHOT')
      end

      it 'marks the artifact as a snapshot' do
        info = nexus_remote.get_artifact_info(snapshot_coordinates)
        doc = REXML::Document.new(info)
        expect(doc.elements['//snapshot'].text).to eq('true')
      end

      it 'uses SNAPSHOT directory with timestamped filename in repository path' do
        info = nexus_remote.get_artifact_info(snapshot_coordinates)
        doc = REXML::Document.new(info)
        expect(doc.elements['//repositoryPath'].text).to eq('/com/example/2.0.1-SNAPSHOT/my-plugin-2.0.1-20240520.203819-1.jar')
      end

      it 'fetches sha1 using SNAPSHOT directory with timestamped filename' do
        nexus_remote.get_artifact_info(snapshot_coordinates)
        expect(nexus_remote).to have_received(:get_response_with_retries)
          .with(snapshot_coordinates, '/myorg/my-repo/com/example/my-plugin/2.0.1-SNAPSHOT/my-plugin-2.0.1-20240520.203819-1.jar.sha1', nil)
      end
    end

    context 'with a release version' do
      before do
        allow(nexus_remote).to receive(:get_response_with_retries)
          .and_return(sha1_value)
      end

      it 'reports the release version' do
        info = nexus_remote.get_artifact_info(release_coordinates)
        doc = REXML::Document.new(info)
        expect(doc.elements['//version'].text).to eq('1.0.0')
      end

      it 'marks the artifact as not a snapshot' do
        info = nexus_remote.get_artifact_info(release_coordinates)
        doc = REXML::Document.new(info)
        expect(doc.elements['//snapshot'].text).to eq('false')
      end

      it 'uses the literal version in the repository path' do
        info = nexus_remote.get_artifact_info(release_coordinates)
        doc = REXML::Document.new(info)
        expect(doc.elements['//repositoryPath'].text).to eq('/com/example/1.0.0/my-plugin-1.0.0.jar')
      end
    end
  end

  describe '#search_for_artifact_endpoint' do
    it 'raises NoMethodError' do
      expect { nexus_remote.search_for_artifact_endpoint(release_coordinates) }
        .to raise_exception(NoMethodError, 'GitHub Packages has no search support')
    end
  end

  describe 'SNAPSHOT with multiple builds' do
    let(:metadata_with_multiple_builds) do
      <<~XML
        <metadata>
          <groupId>com.example</groupId>
          <artifactId>my-plugin</artifactId>
          <version>2.0.1-SNAPSHOT</version>
          <versioning>
            <snapshot>
              <timestamp>20240521.143000</timestamp>
              <buildNumber>3</buildNumber>
            </snapshot>
            <snapshotVersions>
              <snapshotVersion>
                <extension>jar</extension>
                <value>2.0.1-20240519.100000-1</value>
                <updated>20240519100000</updated>
              </snapshotVersion>
              <snapshotVersion>
                <extension>jar</extension>
                <value>2.0.1-20240520.120000-2</value>
                <updated>20240520120000</updated>
              </snapshotVersion>
              <snapshotVersion>
                <extension>jar</extension>
                <value>2.0.1-20240521.143000-3</value>
                <updated>20240521143000</updated>
              </snapshotVersion>
            </snapshotVersions>
            <lastUpdated>20240521143000</lastUpdated>
          </versioning>
        </metadata>
      XML
    end

    before do
      allow(nexus_remote).to receive(:parent_get_artifact_info)
        .with(snapshot_coordinates)
        .and_return(metadata_with_multiple_builds)
    end

    it 'uses the latest build from the snapshot element, not the first snapshotVersion' do
      endpoint = nexus_remote.pull_artifact_endpoint(snapshot_coordinates)
      expect(endpoint).to eq('/myorg/my-repo/com/example/my-plugin/2.0.1-SNAPSHOT/my-plugin-2.0.1-20240521.143000-3.jar')
    end
  end
end
