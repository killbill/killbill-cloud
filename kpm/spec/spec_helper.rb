require 'tmpdir'
require 'kpm'
require 'logger'
require 'rspec'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty           = true
  config.formatter     = 'documentation'
end
