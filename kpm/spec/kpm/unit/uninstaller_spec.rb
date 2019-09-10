# frozen_string_literal: true

require 'spec_helper'

describe KPM::Uninstaller do
  let(:destination) { Dir.mktmpdir('uninstaller_spec') }
  let(:uninstaller) { KPM::Uninstaller.new(destination) }

  let(:plugins_manager_mock) { double(KPM::PluginsManager) }
  let(:sha1_checker_mock) { double(KPM::Sha1Checker) }

  let(:plugin_info) do
    {
      plugin_name: plugin_name,
      plugin_key: plugin_key,
      plugin_path: plugin_path,
      versions: [{ version: version1, :is_default => false, :is_disabled => false, :sha1 => nil }, { version: version2, :is_default => true, :is_disabled => false, :sha1 => nil }],
      type: 'java',
      group_id: 'group',
      artifact_id: 'artifact',
      packaging: 'jar',
      classifier: nil
    }
  end
  let(:plugin_name) { 'plugin-name' }
  let(:plugin_key) { 'plugin-key' }
  let(:plugin_path) { "#{destination}/plugins/java/#{plugin_name}" }
  let(:version1) { '1.0' }
  let(:version2) { '2.0' }

  before do
    KPM::PluginsManager.stub(:new).and_return(plugins_manager_mock)
    KPM::Sha1Checker.stub(:from_file).and_return(sha1_checker_mock)

    # Calls by the Inspector
    plugins_manager_mock.stub(:get_identifier_key_and_entry) do
      [plugin_key, { 'group_id' => plugin_info[:group_id],
                     'artifact_id' => plugin_info[:artifact_id],
                     'packaging' => plugin_info[:packaging] }]
    end
    sha1_checker_mock.stub(:all_sha1) { {} }
  end

  context 'utility methods' do
    it 'raises an error when directory to delete is invalid' do
      expect do
        uninstaller.send(:validate_dir_for_rmrf, '/home/john')
      end.to raise_error(ArgumentError, 'Path /home/john is not a valid directory')
    end
    it 'raises an error when directory to delete is not safe' do
      expect do
        uninstaller.send(:validate_dir_for_rmrf, '/tmp')
      end.to raise_error(ArgumentError, "Path /tmp is not a subdirectory of #{destination}")
    end
  end

  context 'when no plugin is installed' do
    it 'raises an error when uninstalling a plugin' do
      expect do
        uninstaller.uninstall_plugin(plugin_name)
      end.to raise_error(StandardError, "No plugin with key/name '#{plugin_name}' found installed. Try running 'kpm inspect' for more info")
    end

    it 'raises an internal error when uninstalling a plugin' do
      expect do
        uninstaller.send(:remove_all_plugin_versions, plugin_info, true)
      end.to raise_error(ArgumentError, "Path #{plugin_info[:plugin_path]}/#{version1} is not a valid directory")
    end

    it 'raises an error when uninstalling a plugin version' do
      expect do
        uninstaller.send(:remove_plugin_version, plugin_info, '3.0')
      end.to raise_error(ArgumentError, "Path #{plugin_info[:plugin_path]}/3.0 is not a valid directory")
    end
  end

  context 'when plugin is installed' do
    before do
      FileUtils.mkdir_p(plugin_version1_path)
      FileUtils.mkdir_p(plugin_version2_path)
      FileUtils.ln_s(plugin_version2_path, Pathname.new(plugin_path).join('SET_DEFAULT'))
    end
    let(:plugin_version1_path) { File.join(plugin_path, version1) }
    let(:plugin_version2_path) { File.join(plugin_path, version2) }

    it 'looks up a plugin by name' do
      expect(uninstaller.send(:find_plugin, plugin_name)).to eq(plugin_info)
    end

    it 'looks up a plugin by key' do
      expect(uninstaller.send(:find_plugin, plugin_key)).to eq(plugin_info)
    end

    it 'uninstalls if user confirms action' do
      KPM.ui.should_receive(:ask).and_return('y')

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
      plugins_manager_mock.should_receive(:remove_plugin_identifier_key).with(plugin_key)
      sha1_checker_mock.should_receive(:remove_entry!).with("group:artifact:jar:#{version1}")
      sha1_checker_mock.should_receive(:remove_entry!).with("group:artifact:jar:#{version2}")

      uninstaller.uninstall_plugin(plugin_name, true).should be_true
    end
  end
end
