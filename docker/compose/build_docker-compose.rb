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

    if k == 'killbill'
      v['environment'] ||= []
      v['environment'] << 'KILLBILL_METRICS_GRAPHITE=true'
      v['environment'] << 'KILLBILL_METRICS_GRAPHITE_HOST=influxdb'
    elsif k == 'grafana'
      v['environment'] ||= []
      v['environment'] << 'GF_SESSION_PROVIDER=mysql'
      v['environment'] << 'GF_SESSION_PROVIDER_CONFIG=root:killbill@tcp(db:3306)/grafana'
      v['environment'] << 'GF_DATABASE_TYPE=mysql'
      v['environment'] << 'GF_DATABASE_HOST=db:3306'
      v['environment'] << 'GF_DATABASE_USER=root'
      v['environment'] << 'GF_DATABASE_PASSWORD=killbill'

      v['links'] ||= []
      v['links'] << 'db'
    end

    v['log_driver'] ||= 'syslog'
    v['log_opt'] ||= {}
    v['log_opt']['syslog-address'] ||= 'tcp://${HOST_IP}:1514'
  end

  docker_compose = docker_compose.merge(updated)
end

puts docker_compose.to_yaml