require 'spec_helper'
require 'rexml/document'

describe KPM::NexusFacade do

  let(:coordinates_map){ {:version => '0.1.4',
                          :group_id => 'org.kill-bill.billing',
                          :artifact_id => 'killbill-platform-osgi-api',
                          :packaging => 'jar',
                          :classifier => nil} }
  let(:coordinates_with_classifier_map){ {:version => '0.1.1',
                                          :group_id => 'org.kill-bill.billing',
                                          :artifact_id => 'killbill-platform-osgi-bundles-jruby',
                                          :packaging => 'jar',
                                          :classifier => 'javadoc'} }
  let(:coordinates) { KPM::Coordinates.build_coordinates(coordinates_map)}
  let(:coordinates_with_classifier) { KPM::Coordinates.build_coordinates(coordinates_with_classifier_map)}
  let(:nexus_remote) { described_class::RemoteFactory.create(nil, true)}

  it 'when searching for artifacts' do
    response = nil
    expect{  response = nexus_remote.search_for_artifacts(coordinates) }.not_to raise_exception
    expect(REXML::Document.new(response).elements["//artifactId"].text).to eq(coordinates_map[:artifact_id])
  end

  it 'when searching for artifact with classifier' do
    response = nil
    expect{  response = nexus_remote.search_for_artifacts(coordinates_with_classifier) }.not_to raise_exception
    expect(REXML::Document.new(response).elements["//artifactId"].text).to eq(coordinates_with_classifier_map[:artifact_id])
  end

  it 'when getting artifact info' do
    response = nil
    expect{  response = nexus_remote.get_artifact_info(coordinates) }.not_to raise_exception
    expect(REXML::Document.new(response).elements["//version"].text).to eq(coordinates_map[:version])
  end

  it 'when getting artifact info with classifier' do
    response = nil
    expect{  response = nexus_remote.get_artifact_info(coordinates_with_classifier) }.not_to raise_exception
    expect(REXML::Document.new(response).elements["//version"].text).to eq(coordinates_with_classifier_map[:version])
  end

  it 'when pull artifact' do
    response = nil
    destination = Dir.mktmpdir('artifact')
    expect{  response = nexus_remote.pull_artifact(coordinates,destination) }.not_to raise_exception
    destination = File.join(File.expand_path(destination), response[:file_name])
    expect(File.exist?(destination)).to be_true
  end

  it 'when pull artifact with classifier' do
    response = nil
    destination = Dir.mktmpdir('artifact')
    expect{  response = nexus_remote.pull_artifact(coordinates_with_classifier,destination) }.not_to raise_exception
    destination = File.join(File.expand_path(destination), response[:file_name])
    expect(File.exist?(destination)).to be_true
  end

end