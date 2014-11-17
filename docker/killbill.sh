set -a

if ! [ -e /etc/killbill/killbill.properties ]; then
  echo >&2 "Kill Bill properties file not found - creating now..."
  /var/lib/jruby/bin/jruby <<-EORUBY
require 'erb'
require 'yaml'

raw_kpm = File.new('/etc/killbill/kpm.yml.erb').read
parsed_kpm = ERB.new(raw_kpm).result
properties = YAML.load(parsed_kpm)['killbill']['properties']

File.open('/etc/killbill/killbill.properties', 'w') do |file|
  properties.each do |key, value|
    file.write("#{key}=#{value}\n")
  end
end
EORUBY
fi

if ! [ -e /etc/killbill/kpm.yml ]; then
  echo >&2 "Kill Bill kpm file not found - creating now..."
  /var/lib/jruby/bin/jruby <<-EORUBY
require 'erb'
require 'yaml'

raw_kpm = File.new('/etc/killbill/kpm.yml.erb').read
parsed_kpm = ERB.new(raw_kpm).result

File.open('/etc/killbill/kpm.yml', 'w') do |file|
  file.write(parsed_kpm)
end
EORUBY

  echo >&2 "Starting Kill Bill installation..."
  /var/lib/jruby/bin/jruby -S kpm install /etc/killbill/kpm.yml
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