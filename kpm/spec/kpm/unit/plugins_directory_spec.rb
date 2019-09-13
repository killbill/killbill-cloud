# frozen_string_literal: true

require 'spec_helper'

describe KPM::PluginsDirectory do
  it 'should parse the plugins directory' do
    directory = KPM::PluginsDirectory.all(false)
    directory.size.should > 0
  end

  it 'should lookup plugins' do
    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, '0.20')
    group_id.should eq 'org.kill-bill.billing.plugin.java'
    artifact_id.should eq 'analytics-plugin'
    packaging.should eq 'jar'
    classifier.should be_nil
    version.should eq '6.0.1'
    type.should eq :java

    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, 'LATEST')
    group_id.should eq 'org.kill-bill.billing.plugin.java'
    artifact_id.should eq 'analytics-plugin'
    packaging.should eq 'jar'
    classifier.should be_nil
    version.should eq 'LATEST'
    type.should eq :java

    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, '0.42')
    group_id.should eq 'org.kill-bill.billing.plugin.java'
    artifact_id.should eq 'analytics-plugin'
    packaging.should eq 'jar'
    classifier.should be_nil
    version.should eq 'LATEST'
    type.should eq :java
  end
end
