require 'spec_helper'

describe KPM::Installer do

  before(:all) do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::INFO
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
                                                    'plugins'     => {
                                                        'java' => [{
                                                                       'name'    => 'analytics',
                                                                       'version' => '0.7.1'
                                                                   }],
                                                        'ruby' => [{
                                                                       'name'    => 'payment-test-plugin',
                                                                       'artifact_id'    => 'payment-test-plugin',
                                                                       'version' => '1.8.7'
                                                                   },
                                                                   {
                                                                       'name'    => 'stripe'
                                                                   }]
                                                    },
                                                },
                                                'kaui'     => {
                                                    'webapp_path' => kaui_webapp_path
                                                }

                                            },
                                            @logger)

      installer.install
      check_installation(plugins_dir, kb_webapp_path, kaui_webapp_path)

      # Verify idempotency
      installer.install
      check_installation(plugins_dir, kb_webapp_path, kaui_webapp_path)
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
  end
end
