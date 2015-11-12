require 'yaml'

FILES = %w(docker-compose.gi.yml docker-compose.kb.yml)

docker_compose = {}
FILES.each do |filename|
  file = File.new(filename).read
	orig = YAML.load(file)
  updated = orig.each do |k,v|
    unless k == 'influxdb'
      v['links'] ||= []
      v['links'] << 'influxdb'
      v['links'].uniq!
    end

    v['log_driver'] ||= 'syslog'
    v['log_opt'] ||= {}
    v['log_opt']['syslog-address'] ||= 'tcp://${HOST_IP}:1514'
  end

  docker_compose = docker_compose.merge(updated)
end

puts docker_compose.to_yaml