set -a

if ! [ -e $KILLBILL_CONFIG/killbill.properties ]; then
  echo >&2 "Kill Bill properties file not found - creating now..."
  jruby <<-EORUBY
require 'erb'
require 'yaml'

raw_kpm = File.new("#{ENV['KILLBILL_CONFIG']}/kpm.yml.erb").read
parsed_kpm = ERB.new(raw_kpm).result
properties = YAML.load(parsed_kpm)['killbill']['properties']

File.open("#{ENV['KILLBILL_CONFIG']}/killbill.properties", 'w') do |file|
  properties.each do |key, value|
    file.write("#{key}=#{value}\n")
  end
end
EORUBY
fi

if ! [ -e $KILLBILL_CONFIG/kpm.yml ]; then
  echo >&2 "Kill Bill kpm file not found - creating now..."
  jruby <<-EORUBY
require 'erb'
require 'yaml'

raw_kpm = File.new("#{ENV['KILLBILL_CONFIG']}/kpm.yml.erb").read
parsed_kpm = ERB.new(raw_kpm).result

File.open("#{ENV['KILLBILL_CONFIG']}/kpm.yml", 'w') do |file|
  file.write(parsed_kpm)
end
EORUBY

  echo >&2 "Starting Kill Bill installation..."
  jruby -S kpm install $KILLBILL_CONFIG/kpm.yml
fi

source "/etc/default/tomcat7"

JAVA_HOME="/usr/lib/jvm/default-java"
CATALINA_HOME="/usr/share/tomcat7"
CATALINA_BASE="/var/lib/tomcat7"
JAVA_OPTS="-Djava.awt.headless=true -Xmx128m -XX:+UseConcMarkSweepGC"
CATALINA_PID="/var/run/tomcat7.pid"
CATALINA_TMPDIR="/tmp/tomcat7-tomcat7-tmp"
LANG=""
JSSE_HOME="/usr/lib/jvm/default-java/jre/"

cd /var/lib/tomcat7
/usr/share/tomcat7/bin/catalina.sh run