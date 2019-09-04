require 'spec_helper'

describe KPM::Installer do
  context 'when no config file is specified' do
    let(:all_kb_versions) { %w(0.15.0 0.15.1 0.15.10 0.15.11-SNAPSHOT 0.15.2 0.15.3 0.16.0 0.16.1 0.16.10 0.16.11 0.16.12-SNAPSHOT 0.16.2 0.16.3 0.17.0 0.17.1 0.17.2 0.17.2-SNAPSHOT 0.17.3-SNAPSHOT) }

    it 'finds the right stable versions' do
      config = KPM::Installer.build_default_config(all_kb_versions)
      config['killbill'].should_not be_nil
      config['killbill']['version'].should == '0.16.11'

      config['kaui'].should_not be_nil
      config['kaui']['version'].should == 'LATEST'
    end
  end
end
