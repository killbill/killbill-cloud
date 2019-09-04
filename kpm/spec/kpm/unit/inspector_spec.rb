require 'spec_helper'

describe KPM::Inspector do
  before(:each) do
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    tmp_bundles_dir = Dir.mktmpdir
    @bundles_dir = Pathname.new(tmp_bundles_dir).expand_path
    @plugins_dir = @bundles_dir.join('plugins')

    FileUtils.mkdir_p(@plugins_dir)

    @ruby_plugins_dir = @plugins_dir.join('ruby')
    FileUtils.mkdir_p(@ruby_plugins_dir)

    @java_plugins_dir = @plugins_dir.join('java')
    FileUtils.mkdir_p(@java_plugins_dir)

    @manager = KPM::PluginsManager.new(@plugins_dir, @logger)

    @sha1_file = @bundles_dir.join("sha1.yml")
    @sha1_checker = KPM::Sha1Checker.from_file(@sha1_file)
  end

  it 'should parse a correctly setup env' do
    add_plugin('foo', 'plugin_foo', ['1.2.3', '2.0.0', '2.0.1'], 'ruby', 'com.foo', 'foo', 'tar.gz', nil, ['12345', '23456', '34567'], '2.0.1', ['1.2.3'])
    add_plugin('bar', 'plugin_bar', ['1.0.0'], 'java', 'com.bar', 'bar', 'jar', nil, ['98765'], nil, [])

    inspector = KPM::Inspector.new
    all_plugins = inspector.inspect(@bundles_dir)
    all_plugins.size == 2

    all_plugins['plugin_bar']['plugin_key'] == 'bar'
    all_plugins['plugin_bar']['plugin_path'] == @java_plugins_dir.join('plugin_bar').to_s
    all_plugins['plugin_bar'][:versions].size == 1
    all_plugins['plugin_bar'][:versions][0][:version] == '1.0.0'
    all_plugins['plugin_bar'][:versions][0][:is_default] == true
    all_plugins['plugin_bar'][:versions][0][:is_disabled] == false
    all_plugins['plugin_bar'][:versions][0][:sha1] == '98765'

    all_plugins['plugin_foo']['plugin_key'] == 'foo'
    all_plugins['plugin_foo']['plugin_path'] == @ruby_plugins_dir.join('plugin_foo').to_s
    all_plugins['plugin_foo'][:versions].size == 3

    all_plugins['plugin_foo'][:versions][0][:version] == '1.2.3'
    all_plugins['plugin_foo'][:versions][0][:is_default] == false
    all_plugins['plugin_foo'][:versions][0][:is_disabled] == true
    all_plugins['plugin_foo'][:versions][0][:sha1] == '12345'

    all_plugins['plugin_foo'][:versions][1][:version] == '2.0.0'
    all_plugins['plugin_foo'][:versions][1][:is_default] == false
    all_plugins['plugin_foo'][:versions][1][:is_disabled] == false
    all_plugins['plugin_foo'][:versions][1][:sha1] == '23456'

    all_plugins['plugin_foo'][:versions][2][:version] == '2.0.1'
    all_plugins['plugin_foo'][:versions][2][:is_default] == true
    all_plugins['plugin_foo'][:versions][2][:is_disabled] == false
    all_plugins['plugin_foo'][:versions][2][:sha1] == '34567'
  end

  private

  def add_plugin(plugin_key, plugin_name, versions, language, group_id, artifact_id, packaging, classifier, sha1, active_version, disabled_versions)
    plugin_dir = language == 'ruby' ? @ruby_plugins_dir.join(plugin_name) : @java_plugins_dir.join(plugin_name)

    versions.each_with_index do |v, idx|
      coordinate_map = { :group_id => group_id, :artifact_id => artifact_id, :version => v, :packaging => packaging, :classifier => classifier }
      coordinates = KPM::Coordinates.build_coordinates(coordinate_map)

      @manager.add_plugin_identifier_key(plugin_key, plugin_name, language, coordinate_map)
      @sha1_checker.add_or_modify_entry!(coordinates, sha1[idx])

      plugin_dir_version = plugin_dir.join(v)

      FileUtils.mkdir_p(plugin_dir_version)

      # Create some entry to look real
      some_file = 'ruby' ? 'ROOT' : '#{plugin_name}.jar'
      FileUtils.touch(plugin_dir_version.join(some_file))
    end

    @manager.set_active(plugin_dir, active_version) if active_version

    disabled_versions.each do |v|
      @manager.uninstall(plugin_dir, v)
    end
  end
end
