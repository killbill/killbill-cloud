require 'yaml'

yml_kpm = YAML.load_file("#{ENV['KILLBILL_CONFIG']}/kpm.yml")

properties = yml_kpm['killbill']['properties']
properties.each do |key, value|
  puts "#{key}=#{value}"
end