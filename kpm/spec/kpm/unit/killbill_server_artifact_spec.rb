# frozen_string_literal: true

require 'spec_helper'

describe KPM::KillbillServerArtifact do
  describe '.info' do
    let(:oss_parent_pom) do
      properties = %w[killbill-api killbill-plugin-api killbill-commons killbill-platform].map { |p| "<#{p}.version>0.42.4</#{p}.version>" }.join
      "<project><version>0.147.36</version><properties>#{properties}</properties></project>"
    end
    let(:killbill_pom) { '<project><parent><version>0.147.30</version></parent><version>0.25.6</version></project>' }

    # Fake the repository: record what is pulled and write the matching pom
    def stub_pull
      pulled = []
      allow(described_class).to receive(:pull) do |_logger, _group_id, artifact_id, _packaging, _classifier, version, dir, *_|
        pulled << [artifact_id, version]
        file_path = File.join(dir, "#{artifact_id}.pom")
        File.write(file_path, artifact_id == 'killbill' ? killbill_pom : oss_parent_pom)
        { file_path: file_path }
      end
      pulled
    end

    it 'uses the killbill-oss-parent declared by the latest Kill Bill when no version is specified' do
      pulled = stub_pull

      info = described_class.info('LATEST')

      expect(pulled).to eq [%w[killbill LATEST], %w[killbill-oss-parent 0.147.30]]
      expect(info['killbill']).to eq '0.25.6'
      expect(info['killbill-platform']).to eq '0.42.4'
    end

    it 'falls back to the latest killbill-oss-parent when the latest Kill Bill pom is not hosted' do
      pulled = []
      allow(described_class).to receive(:pull) do |_logger, _group_id, artifact_id, _packaging, _classifier, version, dir, *_|
        pulled << [artifact_id, version]
        raise StandardError, 'not found' if artifact_id == 'killbill'

        file_path = File.join(dir, "#{artifact_id}.pom")
        File.write(file_path, oss_parent_pom)
        { file_path: file_path }
      end

      info = described_class.info('LATEST')

      expect(pulled).to eq [%w[killbill LATEST], %w[killbill-oss-parent LATEST]]
      expect(info['killbill']).to be_nil
      expect(info['killbill-oss-parent']).to eq '0.147.36'
      expect(info['killbill-platform']).to eq '0.42.4'
    end

    it 'does not hide the error when the specified Kill Bill pom is not hosted' do
      allow(described_class).to receive(:pull).and_raise(StandardError, 'not found')

      expect { described_class.info('2026.11.13') }.to raise_error(StandardError, 'not found')
    end

    it 'uses the killbill-oss-parent of the specified Kill Bill version' do
      pulled = stub_pull

      info = described_class.info('0.25.6')

      expect(pulled).to eq [%w[killbill 0.25.6], %w[killbill-oss-parent 0.147.30]]
      expect(info['killbill']).to eq '0.25.6'
      expect(info['killbill-platform']).to eq '0.42.4'
    end
  end
end
