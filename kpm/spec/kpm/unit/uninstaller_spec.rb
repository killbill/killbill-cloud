require 'spec_helper'

describe KPM::Uninstaller do
  let(:uninstaller) { KPM::Uninstaller.new(destination) }
  let(:destination) { 'somedir' }

  let(:plugins_manager_mock) { double(KPM::PluginsManager) }
  let(:sha1_checker_mock) { double(KPM::Sha1Checker) }
  before do
    KPM::Inspector.stub_chain(:new, :inspect).and_return(installed_plugins)
    KPM::PluginsManager.stub(:new).and_return(plugins_manager_mock)
    KPM::Sha1Checker.stub(:from_file).and_return(sha1_checker_mock)
  end

  context 'when plugin is not installed' do
    let(:installed_plugins) { {} }

    it 'raises a plugin not found error' do
      expect {
        uninstaller.uninstall_plugin('adyen')
      }.to raise_error(StandardError, "No plugin with key/name 'adyen' found installed. Try running 'kpm inspect' for more info")
    end
  end

  context 'when plugin is installed' do
    let(:installed_plugins) do
      {
        plugin_name => {
          plugin_key: plugin_key,
          plugin_path: plugin_path,
          versions: [{ version: version }],
          group_id: 'group',
          artifact_id: 'artifact',
          packaging: 'jar'
        }
      }
    end

    let(:plugin_name) { 'plugin-name' }
    let(:plugin_key) { 'plugin-key' }
    let(:plugin_path) { 'plugin-path' }
    let(:version) { '1.0' }

    it 'uninstalls a plugin by name' do
      FileUtils.should_receive(:rmtree).with(plugin_path)
      plugins_manager_mock.should_receive(:remove_plugin_identifier_key).with(plugin_key)
      sha1_checker_mock.should_receive(:remove_entry!).with("group:artifact:jar:#{version}")

      uninstaller.uninstall_plugin(plugin_name).should be_true
    end

    it 'uninstalls a plugin by key' do
      FileUtils.should_receive(:rmtree).with(plugin_path)
      plugins_manager_mock.should_receive(:remove_plugin_identifier_key).with(plugin_key)
      sha1_checker_mock.should_receive(:remove_entry!).with("group:artifact:jar:#{version}")

      uninstaller.uninstall_plugin(plugin_key).should be_true
    end
  end

  context 'when plugin is installed' do
    let(:installed_plugins) do
      {
        plugin_name => {
          plugin_key: plugin_key,
          plugin_path: plugin_path,
          versions: [{ version: version1 }, { version: version2 }],
          group_id: 'group',
          artifact_id: 'artifact',
          packaging: 'jar'
        }
      }
    end

    let(:plugin_name) { 'plugin-name' }
    let(:plugin_key) { 'plugin-key' }
    let(:plugin_path) { 'plugin-path' }
    let(:version1) { '1.0' }
    let(:version2) { '2.0' }

    it 'uninstalls if user confirms action' do
      KPM.ui.should_receive(:ask).and_return('y')

      FileUtils.should_receive(:rmtree).with(plugin_path)
      plugins_manager_mock.should_receive(:remove_plugin_identifier_key).with(plugin_key)
      sha1_checker_mock.should_receive(:remove_entry!).with("group:artifact:jar:#{version1}")
      sha1_checker_mock.should_receive(:remove_entry!).with("group:artifact:jar:#{version2}")

      uninstaller.uninstall_plugin(plugin_name).should be_true
    end

    it 'does nothing if user cancels' do
      KPM.ui.should_receive(:ask).and_return('n')

      uninstaller.uninstall_plugin(plugin_name).should be_false
    end

    it 'uninstalls without confirmation if the force option is given' do
      FileUtils.should_receive(:rmtree).with(plugin_path)
      plugins_manager_mock.should_receive(:remove_plugin_identifier_key).with(plugin_key)
      sha1_checker_mock.should_receive(:remove_entry!).with("group:artifact:jar:#{version1}")
      sha1_checker_mock.should_receive(:remove_entry!).with("group:artifact:jar:#{version2}")

      uninstaller.uninstall_plugin(plugin_name, true).should be_true
    end
  end
end
