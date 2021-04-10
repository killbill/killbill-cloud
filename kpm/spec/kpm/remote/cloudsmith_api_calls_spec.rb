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

  # Upload as: cloudsmith push maven -v --group-id com.mycompany.app --artifact-id my-app --packaging pom --version 1.2.3 org/repo my-app-1.2.3.pom
  # <project>
  #   <modelVersion>4.0.0</modelVersion>
  #   <groupId>com.mycompany.app</groupId>
  #   <artifactId>my-app</artifactId>
  #   <version>1.2.3</version>
  #   <packaging>pom</packaging>
  # </project>
  context 'when pulling release artifact' do
    let(:coordinates_map) do
      { version: '1.2.3',
        group_id: 'com.mycompany.app',
        artifact_id: 'my-app',
        packaging: 'pom',
        classifier: nil }
    end
    let(:coordinates) { KPM::Coordinates.build_coordinates(coordinates_map) }

    it {
      response = nil
      expect { response = nexus_remote.get_artifact_info(coordinates) }.not_to raise_exception
      parsed_doc = REXML::Document.new(response)
      expect(parsed_doc.elements['//version'].text).to eq('1.2.3')
      expect(parsed_doc.elements['//repositoryPath'].text).to eq('/com/mycompany/app/1.2.3/my-app-1.2.3.pom')
      expect(parsed_doc.elements['//snapshot'].text).to eq('false')
    }

    it {
      response = nil
      destination = Dir.mktmpdir('artifact')
      expect { response = nexus_remote.pull_artifact(coordinates, destination) }.not_to raise_exception
      destination = File.join(File.expand_path(destination), response[:file_name])
      parsed_pom = REXML::Document.new(File.read(destination))
      expect(parsed_pom.elements['//groupId'].text).to eq('com.mycompany.app')
      expect(parsed_pom.elements['//artifactId'].text).to eq('my-app')
      expect(parsed_pom.elements['//version'].text).to eq('1.2.3')
    }
  end

  # File uploaded twice (the first doesn't have any <properties>)
  # <project>
  #   <modelVersion>4.0.0</modelVersion>
  #   <groupId>com.mycompany.app</groupId>
  #   <artifactId>my-app</artifactId>
  #   <version>1.2.4-SNAPSHOT</version>
  #   <packaging>pom</packaging>
  #   <properties>
  #     <for-kpm>true</for-kpm>
  #   </properties>
  # </project>
  context 'when pulling SNAPSHOT artifact' do
    let(:coordinates_map) do
      { version: '1.2.4-SNAPSHOT',
        group_id: 'com.mycompany.app',
        artifact_id: 'my-app',
        packaging: 'pom',
        classifier: nil }
    end
    let(:coordinates) { KPM::Coordinates.build_coordinates(coordinates_map) }

    it {
      response = nil
      expect { response = nexus_remote.get_artifact_info(coordinates) }.not_to raise_exception
      parsed_doc = REXML::Document.new(response)
      expect(parsed_doc.elements['//version'].text).to eq('1.2.4-SNAPSHOT')
      expect(parsed_doc.elements['//repositoryPath'].text).to eq('/com/mycompany/app/1.2.4-SNAPSHOT/my-app-1.2.4-SNAPSHOT.pom')
      expect(parsed_doc.elements['//snapshot'].text).to eq('true')
    }

    it {
      response = nil
      destination = Dir.mktmpdir('artifact')
      expect { response = nexus_remote.pull_artifact(coordinates, destination) }.not_to raise_exception
      destination = File.join(File.expand_path(destination), response[:file_name])
      parsed_pom = REXML::Document.new(File.read(destination))
      expect(parsed_pom.elements['//groupId'].text).to eq('com.mycompany.app')
      expect(parsed_pom.elements['//artifactId'].text).to eq('my-app')
      expect(parsed_pom.elements['//version'].text).to eq('1.2.4-SNAPSHOT')
      # Verify that if multiple SNAPSHOTs are uploaded, the last one is downloaded (the first one doesn't have <properties>)
      expect(parsed_pom.elements['//properties/for-kpm'].text).to eq('true')
    }
  end
end
