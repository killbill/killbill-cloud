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
      expect{ response = installer.install }.to_not raise_exception
      response = JSON[response]
      response['help'].should be_nil
      response['killbill']['status'].should eq 'INSTALLED'
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
      expect{ response = installer.install }.to_not raise_exception
      response = JSON[response]
      response['help'].should be_nil
      response['kaui']['status'].should eq 'INSTALLED'
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
                                                                   }],
                                                        'ruby' => [{
                                                                       'name' => 'payment-test-plugin',
                                                                       'artifact_id' => 'payment-test-plugin',
                                                                       'group_id' => 'org.kill-bill.billing.plugin.ruby',
                                                                       'version' => '1.8.7'
                                                                   },
                                                                   {
                                                                       'name' => 'stripe'
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

      # Finally verify that for both (well behaved) ruby and java plugin, skipping the install will still correctly return the `:bundle_dir`
      info = installer.install_plugin('payment-test-plugin', nil, 'org.kill-bill.billing.plugin.ruby', 'payment-test-plugin', nil, nil, '1.8.7', plugins_dir)
      info[:bundle_dir].should == plugins_dir + '/plugins/ruby/killbill-payment-test/1.8.7'


      info = installer.install_plugin('analytics', nil, nil, nil,  nil, nil, '0.7.1', plugins_dir)
      info[:bundle_dir].should == plugins_dir + '/plugins/java/analytics-plugin/0.7.1'
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
        plugins_dir + '/plugins/ruby',
        plugins_dir + '/plugins/ruby/killbill-payment-test',
        plugins_dir + '/plugins/ruby/killbill-payment-test/1.8.7',
        plugins_dir + '/plugins/ruby/killbill-stripe'
    ].each do |dir|
      File.directory?(dir).should be_true
    end

    [
        kb_webapp_path,
        kaui_webapp_path,
        plugins_dir + '/platform/jruby.jar',
        plugins_dir + '/plugins/plugin_identifiers.json',
        plugins_dir + '/plugins/java/analytics-plugin/0.7.1/analytics-plugin-0.7.1.jar',
        plugins_dir + '/plugins/ruby/killbill-payment-test/1.8.7/killbill.properties'
    ].each do |file|
      File.file?(file).should be_true
    end

    plugin_identifiers = File.open(plugins_dir + '/plugins/plugin_identifiers.json', 'r') do |f|
      JSON.parse(f.read)
    end

    plugin_identifiers.size.should == 3

    plugin_identifiers['analytics']['plugin_name'].should == 'analytics-plugin'
    plugin_identifiers['analytics']['group_id'].should == 'org.kill-bill.billing.plugin.java'
    plugin_identifiers['analytics']['artifact_id'].should == 'analytics-plugin'
    plugin_identifiers['analytics']['packaging'].should == 'jar'
    plugin_identifiers['analytics']['version'].should == '0.7.1'
    plugin_identifiers['analytics']['language'].should == 'java'

    plugin_identifiers['payment-test-plugin']['plugin_name'].should == 'killbill-payment-test'
    plugin_identifiers['payment-test-plugin']['group_id'].should == 'org.kill-bill.billing.plugin.ruby'
    plugin_identifiers['payment-test-plugin']['artifact_id'].should == 'payment-test-plugin'
    plugin_identifiers['payment-test-plugin']['packaging'].should == 'tar.gz'
    plugin_identifiers['payment-test-plugin']['version'].should == '1.8.7'
    plugin_identifiers['payment-test-plugin']['language'].should == 'ruby'

    plugin_identifiers['stripe']['plugin_name'].should == 'killbill-stripe'
    plugin_identifiers['stripe']['group_id'].should == 'org.kill-bill.billing.plugin.ruby'
    plugin_identifiers['stripe']['artifact_id'].should == 'stripe-plugin'
    plugin_identifiers['stripe']['packaging'].should == 'tar.gz'
    plugin_identifiers['stripe']['version'].should >= '4.0.0'
    plugin_identifiers['stripe']['language'].should == 'ruby'
  end
end
