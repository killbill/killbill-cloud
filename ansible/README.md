# Usage

## killbill_facts

```
# Assume KPM is installed through Rubygems
ansible <HOST_GROUP> -i <HOST_FILE> -m killbill_facts -a 'config_file=/path/to/kpm.yml'

# Self-contained KPM installed
ansible <HOST_GROUP> -i <HOST_FILE> -m killbill_facts -a 'config_file=/path/to/kpm.yml kpm_path=/path/to/kpm-0.5.2-linux-x86_64'

# Without kpm.yml
ansible <HOST_GROUP> -i <HOST_FILE> -m killbill_facts -a 'killbill_web_path=/path/to/apache-tomcat/webapps/ROOT bundles_dir=/var/tmp/bundles'
```