# frozen_string_literal: true

require 'spec_helper'

describe KPM::PluginsDirectory do
  it 'should parse the plugins directory' do
    directory = KPM::PluginsDirectory.all(false)
    expect(directory.size).to be > 0
  end

  it 'should lookup plugins' do
    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, '0.20.11')
    expect(group_id).to eq 'org.kill-bill.billing.plugin.java'
    expect(artifact_id).to eq 'analytics-plugin'
    expect(packaging).to eq 'jar'
    expect(classifier).to be_nil
    expect(version).to eq '6.0.1'
    expect(type).to eq :java

    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, '0.20.11-SNAPSHOT')
    expect(group_id).to eq 'org.kill-bill.billing.plugin.java'
    expect(artifact_id).to eq 'analytics-plugin'
    expect(packaging).to eq 'jar'
    expect(classifier).to be_nil
    expect(version).to eq '6.0.1'
    expect(type).to eq :java

    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, '0.20')
    expect(group_id).to eq 'org.kill-bill.billing.plugin.java'
    expect(artifact_id).to eq 'analytics-plugin'
    expect(packaging).to eq 'jar'
    expect(classifier).to be_nil
    expect(version).to eq '6.0.1'
    expect(type).to eq :java

    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, 'LATEST')
    expect(group_id).to eq 'org.kill-bill.billing.plugin.java'
    expect(artifact_id).to eq 'analytics-plugin'
    expect(packaging).to eq 'jar'
    expect(classifier).to be_nil
    expect(version).to eq 'LATEST'
    expect(type).to eq :java

    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, '0.42')
    expect(group_id).to eq 'org.kill-bill.billing.plugin.java'
    expect(artifact_id).to eq 'analytics-plugin'
    expect(packaging).to eq 'jar'
    expect(classifier).to be_nil
    expect(version).to eq 'LATEST'
    expect(type).to eq :java
  end
end
