# frozen_string_literal: true

require 'tmpdir'
require 'thor'
require 'kpm'
require 'logger'
require 'rspec'
require 'securerandom'
require 'yaml'
require 'killbill_client'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty           = true
  config.formatter     = 'documentation'
  config.filter_run_excluding skip_me_if_nil: true
end

shared_context 'connection_setup' do
  let(:logger) do
    logger = ::Logger.new(STDOUT)
    logger.level = Logger::FATAL
    logger
  end
  let(:yml_file) { YAML.load_file(Dir["#{Dir.pwd}/**/account_spec.yml"][0]) }
  let(:dummy_data_file) { Dir.mktmpdir('dummy') + File::SEPARATOR + 'kbdump' }
  let(:url) { "http://#{yml_file['killbill']['host']}:#{yml_file['killbill']['port']}" }
  let(:killbill_api_key) { yml_file['killbill']['api_key'] }
  let(:killbill_api_secret) { yml_file['killbill']['api_secret'] }
  let(:killbill_user) { yml_file['killbill']['user'] }
  let(:killbill_password) { yml_file['killbill']['password'] }
  let(:db_name) { yml_file['database']['name'] }
  let(:db_username) { yml_file['database']['user'] }
  let(:db_password) { yml_file['database']['password'] }
  let(:db_host) { yml_file['database']['host'] }
  let(:db_port) { yml_file['database']['port'] }
end
