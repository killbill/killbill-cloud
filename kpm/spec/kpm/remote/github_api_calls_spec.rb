# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

describe KPM::NexusFacade, skip_me_if_nil: ENV['TOKEN'].nil? do
  let(:logger) do
    logger = ::Logger.new(STDOUT)
    logger.level = Logger::INFO
    logger
  end
  let(:coordinates_map) do
    { version: '1.1.9',
      group_id: 'org.kill-bill.billing.thirdparty',
      artifact_id: 'qualpay-java-client',
      packaging: 'pom',
      classifier: nil }
  end
  let(:coordinates) { KPM::Coordinates.build_coordinates(coordinates_map) }
  let(:nexus_remote) { described_class::GithubApiCalls.new({ :url => 'https://maven.pkg.github.com/killbill/qualpay-java-client', :token => ENV['TOKEN'] }, true, logger) }

  it {
    # Not implemented
    expect { nexus_remote.search_for_artifacts(coordinates) }.to raise_exception(NoMethodError, 'GitHub Packages has no search support')
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
    expect(File.read(destination)).to match(/qualpay-java-client/)
  }
end
