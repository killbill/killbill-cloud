require 'spec_helper'

describe KPM::PluginsDirectory do

  it 'should parse the plugins directory' do
    directory = KPM::PluginsDirectory.all(false)
    directory.size.should > 0
  end

  it 'should lookup plugins' do
    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, '0.14')
    group_id.should == 'org.kill-bill.billing.plugin.java'
    artifact_id.should == 'analytics-plugin'
    packaging.should == 'jar'
    classifier.should be_nil
    version.should == '1.0.3'
    type.should == :java

    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, 'LATEST')
    group_id.should == 'org.kill-bill.billing.plugin.java'
    artifact_id.should == 'analytics-plugin'
    packaging.should == 'jar'
    classifier.should be_nil
    version.should == 'LATEST'
    type.should == :java

    group_id, artifact_id, packaging, classifier, version, type = KPM::PluginsDirectory.lookup('analytics', false, '0.42')
    group_id.should == 'org.kill-bill.billing.plugin.java'
    artifact_id.should == 'analytics-plugin'
    packaging.should == 'jar'
    classifier.should be_nil
    version.should == 'LATEST'
    type.should == :java
  end
end
