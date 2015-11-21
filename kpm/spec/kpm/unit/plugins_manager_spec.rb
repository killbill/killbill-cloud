require 'spec_helper'

describe KPM::PluginsManager do

  before(:each) do
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    @plugins_dir = Dir.mktmpdir
    @manager = KPM::PluginsManager.new(@plugins_dir, logger)

    @plugin_dir = Pathname.new(@plugins_dir).join('ruby').join('killbill-stripe')
    FileUtils.mkdir_p(@plugin_dir)
    FileUtils.mkdir_p(@plugin_dir.join('1.0.0'))
    FileUtils.mkdir_p(@plugin_dir.join('2.0.0'))

    File.exists?(@plugin_dir.join('ACTIVE')).should be_false
  end

  after(:each) do
    FileUtils.remove_entry_secure @plugins_dir
  end

  it 'sets a path as active' do
    @manager.set_active(@plugin_dir.join('1.0.0'))
    File.exists?(@plugin_dir.join('ACTIVE')).should be_true
    File.readlink(@plugin_dir.join('ACTIVE')).should == @plugin_dir.join('1.0.0').to_s

    @manager.set_active(@plugin_dir.join('2.0.0'))
    File.exists?(@plugin_dir.join('ACTIVE')).should be_true
    File.readlink(@plugin_dir.join('ACTIVE')).should == @plugin_dir.join('2.0.0').to_s
  end

  it 'sets a plugin version as active' do
    @manager.set_active('killbill-stripe', '2.0.0')
    File.exists?(@plugin_dir.join('ACTIVE')).should be_true
    File.readlink(@plugin_dir.join('ACTIVE')).should == @plugin_dir.join('2.0.0').to_s

    @manager.set_active('killbill-stripe', '1.0.0')
    File.exists?(@plugin_dir.join('ACTIVE')).should be_true
    File.readlink(@plugin_dir.join('ACTIVE')).should == @plugin_dir.join('1.0.0').to_s
  end

  it 'uninstalls a plugin via a path' do
    @manager.uninstall(@plugin_dir.join('1.0.0'))
    check_state('1.0.0', false, true)
    check_state('2.0.0', false, false)

    @manager.uninstall(@plugin_dir.join('2.0.0'))
    check_state('1.0.0', false, true)
    check_state('2.0.0', false, true)
  end

  it 'uninstalls a plugin via name' do
    @manager.uninstall('killbill-stripe', '1.0.0')
    check_state('1.0.0', false, true)
    check_state('2.0.0', false, false)

    @manager.uninstall('killbill-stripe', '2.0.0')
    check_state('1.0.0', false, true)
    check_state('2.0.0', false, true)
  end

  it 'restarts a plugin via a path' do
    @manager.restart(@plugin_dir.join('1.0.0'))
    check_state('1.0.0', true, false)
    check_state('2.0.0', false, false)

    @manager.restart(@plugin_dir.join('2.0.0'))
    check_state('1.0.0', true, false)
    check_state('2.0.0', true, false)
  end

  it 'restarts a plugin via name' do
    @manager.restart('killbill-stripe', '1.0.0')
    check_state('1.0.0', true, false)
    check_state('2.0.0', false, false)

    @manager.restart('killbill-stripe', '2.0.0')
    check_state('1.0.0', true, false)
    check_state('2.0.0', true, false)
  end

  it 'guesses the plugin name' do
    @manager.guess_plugin_name('tripe').should be_nil
    # Short name
    @manager.guess_plugin_name('stripe').should == 'killbill-stripe'
    # Artifact id
    @manager.guess_plugin_name('stripe-plugin').should == 'killbill-stripe'
    # Plugin name (top directory in the .tar.gz)
    @manager.guess_plugin_name('killbill-stripe').should == 'killbill-stripe'
  end

  private

  def check_state(version, has_restart, has_stop)
    File.exists?(@plugin_dir.join(version).join('tmp').join('restart.txt')).should == has_restart
    File.exists?(@plugin_dir.join(version).join('tmp').join('stop.txt')).should == has_stop
  end
end
