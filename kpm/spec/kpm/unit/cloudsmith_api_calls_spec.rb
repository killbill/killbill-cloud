# frozen_string_literal: true

require 'spec_helper'

describe KPM::NexusFacade::CloudsmithApiCalls do
  let(:logger) { ::Logger.new(nil) }
  let(:nexus_remote) { described_class.new({ url: 'https://dl.cloudsmith.io/token/org/repo/maven' }, true, logger) }
  let(:metadata) do
    '<metadata><versioning><latest>0.147.37-SNAPSHOT</latest><release>0.147.36</release></versioning></metadata>'
  end

  describe '#get_artifact_info' do
    it 'resolves LATEST from the artifact maven-metadata.xml' do
      requested = []
      allow(nexus_remote).to receive(:get_response_with_retries) do |_coordinates, endpoint, _params|
        requested << endpoint
        endpoint.end_with?('maven-metadata.xml') ? metadata : 'sha1-value'
      end

      info = REXML::Document.new(nexus_remote.get_artifact_info('org.kill-bill.billing:killbill-oss-parent:pom:LATEST'))

      expect(info.elements['//version'].text).to eq '0.147.36'
      expect(info.elements['//sha1'].text).to eq 'sha1-value'
      expect(requested.first).to eq '/token/org/repo/maven/org/kill-bill/billing/killbill-oss-parent/maven-metadata.xml'
      expect(requested.last).to eq '/token/org/repo/maven/org/kill-bill/billing/killbill-oss-parent/0.147.36/killbill-oss-parent-0.147.36.pom.sha1'
    end

    it 'does not look up the metadata when the version is specified' do
      allow(nexus_remote).to receive(:get_response_with_retries).and_return('sha1-value')

      nexus_remote.get_artifact_info('org.kill-bill.billing:killbill-oss-parent:pom:0.147.36')

      expect(nexus_remote).to have_received(:get_response_with_retries).once
    end

    it 'fails when the metadata has no version' do
      allow(nexus_remote).to receive(:get_response_with_retries).and_return('<metadata><versioning/></metadata>')

      expect { nexus_remote.get_artifact_info('org.kill-bill.billing:killbill-oss-parent:pom:LATEST') }.to raise_error(KPM::NexusFacade::ArtifactNotFoundException, /Unable to find the latest version/)
    end
  end
end
