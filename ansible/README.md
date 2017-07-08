# Usage

## play.yml playbook

```
ansible-playbook -i <HOST_FILE> play.yml
```

The playbook has several roles:

* common: Ansible setup (defines `ansible_ruby_interpreter`)
* tomcat: `$CATALINA_BASE` setup (does not install nor manage Tomcat itself)
* kpm: KPM setup and installation
* killbill: Kill Bill setup and installation

Configuration:

* [group_vars/all.yml](group_vars/all.yml) defines what to install (KPM version, Kill Bill version, plugins, etc.) and the main configuration options. This could be overridden in a child `group_vars` or even in `host_vars` (https://docs.ansible.com/ansible/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)
* [roles/killbill/templates/killbill.properties.j2](roles/killbill/templates/killbill.properties.j2) is the main Kill Bill configuration file
* [roles/tomcat/templates/setenv.sh.j2](roles/tomcat/templates/setenv.sh.j2) defines JVM level system properties

Tomcat will automatically be restarted is `catalina_home` is defined.

## tomcat_ubuntu playbook

Example playbook on how to install Tomcat on Ubuntu:

```
ansible-playbook -i <HOST_FILE> tomcat_ubuntu.yml
ansible-playbook -i <HOST_FILE> play.yml
```

# Internals

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
