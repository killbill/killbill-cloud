# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

describe KPM::NexusFacade, skip_me_if_nil: ENV['CLOUDSMITH_TOKEN'].nil? do
  let(:logger) do
    logger = ::Logger.new(STDOUT)
    logger.level = Logger::INFO
    logger
  end
  let(:coordinates_map) do
    { version: '0.22.21-20210319.010242-1',
      group_id: 'org.kill-bill.billing',
      artifact_id: 'killbill',
      packaging: 'pom',
      classifier: nil }
  end
  let(:coordinates) { KPM::Coordinates.build_coordinates(coordinates_map) }
  let(:nexus_remote) { described_class::CloudsmithApiCalls.new({ :url => "https://dl.cloudsmith.io/#{ENV['CLOUDSMITH_TOKEN']}/#{ENV['CLOUDSMITH_ORG']}/#{ENV['CLOUDSMITH_REPO']}/maven" }, true, logger) }

  it {
    # Not implemented
    expect { nexus_remote.search_for_artifacts(coordinates) }.to raise_exception(NoMethodError, 'Cloudsmith has no search support')
  }

  it {
    response = nil
    expect { response = nexus_remote.get_artifact_info(coordinates) }.not_to raise_exception
    expect(REXML::Document.new(response).elements['//version'].text).to eq(coordinates_map[:version])
  }

  it {
    response = nil
    destination = Dir.mktmpdir('artifact')
    expect { response = nexus_remote.pull_artifact(coordinates, destination) }.not_to raise_exception
    destination = File.join(File.expand_path(destination), response[:file_name])
    expect(File.read(destination)).to match(/org.kill-bill.billing/)
  }
end
