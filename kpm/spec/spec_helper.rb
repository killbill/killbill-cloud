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
end
