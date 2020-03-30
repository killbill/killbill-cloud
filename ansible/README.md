# Installation

You can run the playbooks directly from this directory.

Alternatively, if you would prefer embedding the roles in your own playbooks, you can do so via Ansible Galaxy.

## Ansible Galaxy

1. Update your `ansible.cfg` with:

```
[defaults]
roles_path = ~/.ansible/roles/
library = ~/.ansible/roles/killbill-cloud/ansible/library
```

2. Create a file `requirements.yml`:

```
- src: https://github.com/killbill/killbill-cloud
```

then run `ansible-galaxy install -r requirements.yml`.

The roles can now be referenced in your playbooks via `killbill-cloud/ansible/roles/XXX` (e.g. `killbill-cloud/ansible/roles/kpm`).

# Usage

Requirements:

* Java must be pre-installed on the target hosts (e.g. install the openjdk-8-jdk package on Ubuntu). In the rest of this documentation, we will assume `$TARGET_JAVA_HOME` points to the Java home installation on the *target* hosts (e.g. `/usr/lib/jvm/java-8-openjdk-amd64`).
* Before installing Kill Bill and/or Kaui, KPM must be installed via the kpm.yml playbook.


## kpm.yml playbook

Playbook to install KPM as a self-contained utility (no Ruby dependency needed):

```
ansible-playbook -i <INVENTORY> kpm.yml
```

## tomcat.yml playbook

If you don't need a custom Tomcat installation, you can use the `tomcat.yml` playbook to install a Kill Bill compatible Tomcat version:

```
ansible-playbook -i <INVENTORY> -e java_home=$TARGET_JAVA_HOME tomcat.yml
```

For performance reasons, we recommend installing the Apache Tomcat native libraries. To do so, you need to pass a few more options to the playbook:

* `gnu_arch`: the target architecture (e.g. output of `dpkg-architecture --query DEB_BUILD_GNU_TYPE`).
* `apr_config_path`: the path to `apr-1-config` (you must install the Apache Portable Runtime Library separately, i.e. `libapr1-dev`).
* `tomcat_native_libdir`: output path where the libraries will be installed.


You also need to install the OpenSSL library separately (e.g. `libssl-dev`).

```
ansible-playbook -i <INVENTORY> -e java_home=$TARGET_JAVA_HOME -e apr_config_path=/usr/bin/apr-1-config -e gnu_arch=x86_64-linux-gnu -e tomcat_native_libdir=/usr/share/tomcat/native-jni-lib tomcat.yml
```

## killbill.yml playbook

Playbook to install Kill Bill:

```
ansible-playbook -i <INVENTORY> -e java_home=$TARGET_JAVA_HOME killbill.yml
```

It is expected that the `/var/lib/killbill/kpm.yml` file already exists on the target machine, for example:

```
---
killbill:
  version: LATEST
  plugins_dir: /var/lib/killbill/bundles
  webapp_path: /var/lib/tomcat/webapps/ROOT.war
```

The playbook has several roles:

* common: Ansible setup (defines `ansible_ruby_interpreter`)
* tomcat: `$CATALINA_BASE` setup (does not install nor manage Tomcat itself)
* killbill: Kill Bill setup and installation

Configuration:

* [group_vars/all.yml](group_vars/all.yml) defines what to install (KPM version, Kill Bill version, plugins, etc.) and the main configuration options. This could be overridden in a child `group_vars` or even in `host_vars` (https://docs.ansible.com/ansible/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)
* [templates/killbill/killbill.properties.j2](templates/killbill/killbill.properties.j2) is the main Kill Bill configuration file
* [templates/tomcat/conf/setenv.sh.j2](templates/tomcat/conf/setenv.sh.j2) defines JVM level system properties

## migrations.yml playbook

Playbook to manage Kill Bill (and its plugins) database migrations.

Assuming Kill Bill is installed locally (`/var/lib/tomcat/webapps/ROOT.war` by default) and your `kpm.yml` (`/var/lib/killbill/kpm.yml` by default) points to the **new** version of Kill Bill:

```
ansible-playbook -i localhost, -e ansible_connection=local -e gh_token=XXX migrations.yml
```

This will install Flyway, fetch all migrations and prompt the user whether they should be applied.

## plugin.yml playbook

Allow to restart a specific plugin

For example to restart `adyen` plugin
```
ansible-playbook -i <HOST_FILE> plugin.yml --extra-vars "plugin_key=adyen"
```

# Extending

To build upon these roles, you can create your own play, e.g.:

```
---
- name: Deploy Kill Bill
  hosts: all
  tasks:
    - name: setup Ruby
      include_role:
        name: killbill-cloud/ansible/roles/common
    - name: setup Tomcat conf files
      include_role:
        name: killbill-cloud/ansible/roles/tomcat
    - name: install Kill Bill
      include_role:
        name: killbill-cloud/ansible/roles/killbill
    - name: customize Kill Bill
      import_tasks: roles/acme/tasks/main.yml
```

Note that you need to have your own templates directory, containing your own templates.

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
 

# Testing Playbooks

In order to test, one can an inventory:

## Locally

```
# File localhost/inventory 
[server]
127.0.0.1 ansible_user=sbrossier
```

```
> ansible-playbook -v -i localhost/inventory -e java_home=/Library/Java/JavaVirtualMachines/jdk1.8.0_171.jdk/Contents/Home  -u <user> the _playbook.yml
```

