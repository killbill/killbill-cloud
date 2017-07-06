# Usage

## play.yml playbook

```
ansible-playbook -i <HOST_FILE> play.yml
```

## killbill_facts module

```
# Assume KPM is installed through Rubygems
ansible <HOST_GROUP> -i <HOST_FILE> -m killbill_facts -a 'config_file=/path/to/kpm.yml'

# Self-contained KPM installed
ansible <HOST_GROUP> -i <HOST_FILE> -m killbill_facts -a 'config_file=/path/to/kpm.yml kpm_path=/path/to/kpm-0.5.2-linux-x86_64'

# Without kpm.yml
ansible <HOST_GROUP> -i <HOST_FILE> -m killbill_facts -a 'killbill_web_path=/path/to/apache-tomcat/webapps/ROOT bundles_dir=/var/tmp/bundles'
```

Ansible requires the module file to start with `/usr/bin/ruby` to allow for shebang line substitution. If no Ruby interpreter is available at that path, you can configure it through `ansible_ruby_interpreter`, which is set per-host as an inventory variable associated with a host or group of hosts (e.g. `ansible_ruby_interpreter=/opt/kpm-0.5.2-linux-x86_64/lib/ruby/bin/ruby` in your host file).
