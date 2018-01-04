require 'yaml'

FILES = %w(docker-compose.gi.yml docker-compose.kb.yml)

docker_compose = {
  'version' => '3.2',
  'volumes' => {'db' => {}, 'influxdb' => {}},
  'services' => {}
}

docker_compose['services'].merge!(YAML.load(File.new('docker-compose.gi.yml').read)['services'])
docker_compose['services'].merge!(YAML.load(File.new('docker-compose.kb.yml').read)['services'])

docker_compose['services']['killbill']['environment'] ||= []
docker_compose['services']['killbill']['environment'] << 'KILLBILL_METRICS_INFLUXDB=true'
docker_compose['services']['killbill']['environment'] << 'KILLBILL_METRICS_INFLUXDB_HOST=influxdb'
docker_compose['services']['killbill']['environment'] << 'KILLBILL_METRICS_INFLUXDB_PORT=8086'

docker_compose['services']['grafana']['environment'] ||= []
docker_compose['services']['grafana']['environment'] << 'GF_SESSION_PROVIDER=mysql'
docker_compose['services']['grafana']['environment'] << 'GF_SESSION_PROVIDER_CONFIG=root:killbill@tcp(db:3306)/grafana'
docker_compose['services']['grafana']['environment'] << 'GF_DATABASE_TYPE=mysql'
docker_compose['services']['grafana']['environment'] << 'GF_DATABASE_HOST=db:3306'
docker_compose['services']['grafana']['environment'] << 'GF_DATABASE_USER=root'
docker_compose['services']['grafana']['environment'] << 'GF_DATABASE_PASSWORD=killbill'

docker_compose['services'].each do |k,v|
  v['logging'] ||= {}
  v['logging']['driver'] ||= 'syslog'
  v['logging']['options'] ||= {}
  v['logging']['options']['syslog-address'] ||= 'tcp://${HOST_IP}:1514'
end

puts docker_compose.to_yaml
