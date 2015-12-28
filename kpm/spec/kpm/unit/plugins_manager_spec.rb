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

    File.exists?(@plugin_dir.join('SET_DEFAULT')).should be_false
  end

  after(:each) do
    FileUtils.remove_entry_secure @plugins_dir
  end

  it 'creates a plugin identifier entry with no coordinate' do
    # Verifies file gets created if does not exist
    identifiers = @manager.add_plugin_identifier_key('foo', 'foo_name', 'type', nil)
    identifiers.size.should == 1
    identifiers['foo']['plugin_name'].should == 'foo_name'
  end

  it 'creates a plugin identifier entry with coordinates' do
    # Verifies file gets created if does not exist
    identifiers = @manager.add_plugin_identifier_key('bar', 'bar_name', 'type', ['group', 'artifact', 'packaging', nil, 'version'])
    identifiers.size.should == 1
    identifiers['bar']['plugin_name'].should == 'bar_name'
    identifiers['bar']['group_id'].should == 'group'
    identifiers['bar']['artifact_id'].should == 'artifact'
    identifiers['bar']['packaging'].should == 'packaging'
    identifiers['bar']['classifier'].should == nil
    identifiers['bar']['version'].should == 'version'
  end


  it 'creates plugin identifier with multiple entries' do
    # Verifies file gets created if does not exist
    identifiers = @manager.add_plugin_identifier_key('foo', 'foo_name', 'type', nil)
    identifiers.size.should == 1
    identifiers['foo']['plugin_name'].should == 'foo_name'

    # Verify file was created from previous entry (prev value was read)
    identifiers = @manager.add_plugin_identifier_key('bar', 'bar_name', 'type', nil)
    identifiers.size.should == 2
    identifiers['foo']['plugin_name'].should == 'foo_name'
    identifiers['bar']['plugin_name'].should == 'bar_name'


    # Verify file was created from previous entry (prev value was read)
    identifiers = @manager.add_plugin_identifier_key('zoe', 'zoe_name', 'type', nil)
    identifiers.size.should == 3
    identifiers['bar']['plugin_name'].should == 'bar_name'
    identifiers['foo']['plugin_name'].should == 'foo_name'
    identifiers['zoe']['plugin_name'].should == 'zoe_name'
  end

  it 'creates plugin identifiers with duplicate entries' do
    # Verifies file gets created if does not exist
    identifiers = @manager.add_plugin_identifier_key('kewl', 'kewl_name', 'type', nil)
    identifiers.size.should == 1
    identifiers['kewl']['plugin_name'].should == 'kewl_name'

    # Add with a different plugin_name
    identifiers = @manager.add_plugin_identifier_key('kewl', 'kewl_name2', 'type', nil)
    identifiers.size.should == 1
    identifiers['kewl']['plugin_name'].should == 'kewl_name'
  end


  it 'creates plugin identifiers and remove entry' do
    # Verifies file gets created if does not exist
    identifiers = @manager.add_plugin_identifier_key('lol', 'lol_name', 'type', nil)
    identifiers.size.should == 1
    identifiers['lol']['plugin_name'].should == 'lol_name'

    # Remove wrong entry, nothing happens
    identifiers = @manager.remove_plugin_identifier_key('lol2')
    identifiers.size.should == 1
    identifiers['lol']['plugin_name'].should == 'lol_name'

    # Remove correct entry
    identifiers = @manager.remove_plugin_identifier_key('lol')
    identifiers.size.should == 0

    # Add same entry again
    identifiers = @manager.add_plugin_identifier_key('lol', 'lol_name', 'type', nil)
    identifiers.size.should == 1
    identifiers['lol']['plugin_name'].should == 'lol_name'
  end

  it 'creates plugin identifiers and validate entry' do
    # Verifies file gets created if does not exist
    identifiers = @manager.add_plugin_identifier_key('yoyo', 'yoyo_name', 'type',  ['group', 'artifact', 'packaging', nil, 'version'])
    identifiers.size.should == 1
    identifiers['yoyo']['plugin_name'].should == 'yoyo_name'

    @manager.validate_plugin_identifier_key('yoyo', ['group', 'artifact', 'packaging', nil, 'version']).should == true

    # Negative validation
    @manager.validate_plugin_identifier_key('yoyo', ['group1', 'artifact', 'packaging', nil, 'version']).should == false
  end


  it 'creates a plugin identifier entry with a new version' do
    # Verifies file gets created if does not exist
    identifiers = @manager.add_plugin_identifier_key('bar', 'bar_name', 'type', ['group', 'artifact', 'packaging', nil, 'version1'])
    identifiers.size.should == 1
    identifiers['bar']['plugin_name'].should == 'bar_name'
    identifiers['bar']['version'].should == 'version1'

    identifiers = @manager.add_plugin_identifier_key('bar', 'bar_name', 'type', ['group', 'artifact', 'packaging', nil, 'version2'])
    identifiers.size.should == 1
    identifiers['bar']['plugin_name'].should == 'bar_name'
    identifiers['bar']['version'].should == 'version2'

  end

  it 'sets a path as active' do
    @manager.set_active(@plugin_dir.join('1.0.0'))
    File.exists?(@plugin_dir.join('SET_DEFAULT')).should be_true
    File.readlink(@plugin_dir.join('SET_DEFAULT')).should == @plugin_dir.join('1.0.0').to_s

    @manager.set_active(@plugin_dir.join('2.0.0'))
    File.exists?(@plugin_dir.join('SET_DEFAULT')).should be_true
    File.readlink(@plugin_dir.join('SET_DEFAULT')).should == @plugin_dir.join('2.0.0').to_s
  end

  it 'sets a plugin version as active' do
    @manager.set_active('killbill-stripe', '2.0.0')
    File.exists?(@plugin_dir.join('SET_DEFAULT')).should be_true
    File.readlink(@plugin_dir.join('SET_DEFAULT')).should == @plugin_dir.join('2.0.0').to_s

    @manager.set_active('killbill-stripe', '1.0.0')
    File.exists?(@plugin_dir.join('SET_DEFAULT')).should be_true
    File.readlink(@plugin_dir.join('SET_DEFAULT')).should == @plugin_dir.join('1.0.0').to_s
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

  def check_state(version, has_restart, has_disabled)
    File.exists?(@plugin_dir.join(version).join('tmp').join('restart.txt')).should == has_restart
    File.exists?(@plugin_dir.join(version).join('tmp').join('disabled.txt')).should == has_disabled
  end
end
