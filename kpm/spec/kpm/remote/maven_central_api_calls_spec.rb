# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

describe KPM::NexusFacade do
  let(:logger) do
    logger = ::Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    logger
  end
  let(:coordinates_map) do
    { version: '0.24.15',
      group_id: 'org.kill-bill.billing',
      artifact_id: 'killbill',
      packaging: 'pom',
      classifier: nil }
  end
  let(:coordinates) { KPM::Coordinates.build_coordinates(coordinates_map) }
  let(:nexus_remote) { described_class::MavenCentralApiCalls.new({}, nil, logger) }

  context 'when pulling release artifact' do
    it {
      response = nil
      expect { response = nexus_remote.get_artifact_info(coordinates) }.not_to raise_exception
      parsed_doc = REXML::Document.new(response)
      expect(parsed_doc.elements['//version'].text).to eq('0.24.15')
      expect(parsed_doc.elements['//repositoryPath'].text).to eq('/org/kill-bill/billing/0.24.15/killbill-0.24.15.pom')
      expect(parsed_doc.elements['//snapshot'].text).to eq('false')
    }

    it {
      response = nil
      destination = Dir.mktmpdir('artifact')
      expect { response = nexus_remote.pull_artifact(coordinates, destination) }.not_to raise_exception
      destination = File.join(File.expand_path(destination), response[:file_name])
      parsed_pom = REXML::Document.new(File.read(destination))
      expect(parsed_pom.elements['//groupId'].text).to eq('org.kill-bill.billing')
      expect(parsed_pom.elements['//artifactId'].text).to eq('killbill-oss-parent')
      expect(parsed_pom.elements['//version'].text).to eq('0.146.63')
    }
  end
end
