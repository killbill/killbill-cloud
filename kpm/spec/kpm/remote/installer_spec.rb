# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe KPM::Installer do
  before(:all) do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  it 'should be able to install only Kill Bill' do
    Dir.mktmpdir do |dir|
      kb_webapp_path   = dir + '/KB_ROOT.war'
      installer        = KPM::Installer.new({
                                              'killbill' => {
                                                'webapp_path' => kb_webapp_path
                                              }
                                            },
                                            @logger)

      # No exception
      response = nil
      expect { response = installer.install }.to_not raise_exception
      response = JSON[response]
      expect(response['help']).to be_nil
      expect(response['killbill']['status']).to eq 'INSTALLED'
    end
  end

  it 'should be able to install only Kaui' do
    Dir.mktmpdir do |dir|
      kaui_webapp_path = dir + '/KAUI_ROOT.war'
      installer        = KPM::Installer.new({
                                              'kaui' => {
                                                'webapp_path' => kaui_webapp_path
                                              }
                                            },
                                            @logger)

      # No exception
      response = nil
      expect { response = installer.install }.to_not raise_exception
      response = JSON[response]
      expect(response['help']).to be_nil
      expect(response['kaui']['status']).to eq 'INSTALLED'
    end
  end

  it 'should be able to install all artifacts' do
    Dir.mktmpdir do |dir|
      kb_webapp_path   = dir + '/KB_ROOT.war'
      kaui_webapp_path = dir + '/KAUI_ROOT.war'
      plugins_dir      = dir + '/bundles'
      installer        = KPM::Installer.new({
                                              'killbill' => {
                                                'webapp_path' => kb_webapp_path,
                                                'plugins_dir' => plugins_dir,
                                                'plugins' => {
                                                  'java' => [{
                                                    'name' => 'analytics',
                                                    'version' => '0.7.1'
                                                  }, {
                                                    'name' => 'stripe',
                                                    'version' => '7.0.0'
                                                  }]
                                                }
                                              },
                                              'kaui' => {
                                                'webapp_path' => kaui_webapp_path
                                              }
                                            },
                                            @logger)

      installer.install
      check_installation(plugins_dir, kb_webapp_path, kaui_webapp_path)

      # Verify idempotency
      installer.install
      check_installation(plugins_dir, kb_webapp_path, kaui_webapp_path)

      # Finally verify that for (well behaved) java plugins, skipping the install will still correctly return the `:bundle_dir`
      info = installer.install_plugin('analytics', nil, nil, nil, nil, nil, '0.7.1', plugins_dir)
      expect(info[:bundle_dir]).to eq plugins_dir + '/plugins/java/analytics-plugin/0.7.1'
    end
  end

  private

  def check_installation(plugins_dir, kb_webapp_path, kaui_webapp_path)
    [
      plugins_dir,
      plugins_dir + '/platform',
      plugins_dir + '/plugins',
      plugins_dir + '/plugins/java',
      plugins_dir + '/plugins/java/analytics-plugin',
      plugins_dir + '/plugins/java/analytics-plugin/0.7.1',
      plugins_dir + '/plugins/java/stripe-plugin',
      plugins_dir + '/plugins/java/stripe-plugin/7.0.0'
    ].each do |dir|
      expect(File.directory?(dir)).to be_truthy
    end

    [
      kb_webapp_path,
      kaui_webapp_path,
      plugins_dir + '/plugins/plugin_identifiers.json',
      plugins_dir + '/plugins/java/analytics-plugin/0.7.1/analytics-plugin-0.7.1.jar',
      plugins_dir + '/plugins/java/stripe-plugin/7.0.0/stripe-plugin-7.0.0.jar'
    ].each do |file|
      expect(File.file?(file)).to be_truthy
    end

    plugin_identifiers = File.open(plugins_dir + '/plugins/plugin_identifiers.json', 'r') do |f|
      JSON.parse(f.read)
    end

    expect(plugin_identifiers.size).to eq 2

    expect(plugin_identifiers['analytics']['plugin_name']).to eq 'analytics-plugin'
    expect(plugin_identifiers['analytics']['group_id']).to eq 'org.kill-bill.billing.plugin.java'
    expect(plugin_identifiers['analytics']['artifact_id']).to eq 'analytics-plugin'
    expect(plugin_identifiers['analytics']['packaging']).to eq 'jar'
    expect(plugin_identifiers['analytics']['version']).to eq '0.7.1'
    expect(plugin_identifiers['analytics']['language']).to eq 'java'

    expect(plugin_identifiers['stripe']['plugin_name']).to eq 'stripe-plugin'
    expect(plugin_identifiers['stripe']['group_id']).to eq 'org.kill-bill.billing.plugin.java'
    expect(plugin_identifiers['stripe']['artifact_id']).to eq 'stripe-plugin'
    expect(plugin_identifiers['stripe']['packaging']).to eq 'jar'
    expect(plugin_identifiers['stripe']['version']).to eq '7.0.0'
    expect(plugin_identifiers['stripe']['language']).to eq 'java'
  end
end
