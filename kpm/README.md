# KPM: the Kill Bill Package Manager

The goal of KPM is to facilitate the installation of Kill Bill, its plugins and Kaui.

kpm can be used interactively to search and download individual artifacts (Kill Bill war, plugins, etc.) or to perform an automatic Kill Bill installation using a configuration file.

## Prerequisites

### Java

Kill Bill runs on the [Java](https://www.java.com/en/download/) platform, version 6 and above (8 is recommended).

## Installation

### Pre-built binaries (recommended, Linux and MacOS only)

Note that this installation method assumes `/bin/bash` to be available on your system.

KPM builds are available on [Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.kill-bill.billing.installer%22%20AND%20a%3A%22kpm%22) with coordinates `org.kill-bill.billing.installer:kpm`.

Download the package matching your architecture.

### Through Rubygems

Ruby is required to run KPM itself (it is not a dependency of Kill Bill).

Ruby 2.1+ or JRuby 1.7.20+ is recommended. If you don't have a Ruby installation yet, use [RVM](https://rvm.io/rvm/install):

```
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby
```

After following the post-installation instructions, you should have access to the `ruby` and `gem` executables.

You can the run:

    gem install kpm

## Quick start

The following commands

    mkdir killbill
    cd killbill
    kpm install

will setup [Kill Bill](https://github.com/killbill/killbill) and [Kaui](https://github.com/killbill/killbill-admin-ui-standalone), i.e.:

* [Tomcat](http://tomcat.apache.org/) (open-source Java web server) is setup in the `killbill` directory
* The Kill Bill application (war) is installed in the `killbill/webapps` directory
* The Kill Bill UI (Kaui war) is installed in the `killbill/webapps` directory
* Default plugins are installed in the `/var/tmp/bundles` directory, among them:
 * `jruby.jar`, required to run Ruby plugins
 * the [KPM plugin](https://github.com/killbill/killbill-kpm-plugin), required to (un-)install plugins at runtime

To start Kill Bill, simply run

    ./bin/catalina.sh run

You can then verify Kill Bill is running by going to http://127.0.0.1:8080/kaui.

## Using KPM

### Custom Installation Through `kpm.yml` File

KPM allows you to specify a configuration file, `kpm.yml`, to describe what should be installed. The configuration file is a `yml`. The following shows the syntax of the `kpm.yml` file:

    killbill:
      version: 0.14.0
      plugins:
        java:
          - name: analytics
        ruby:
          - name: stripe

This instructs kpm to:

* Download Kill Bill version 0.14.0
* Setup the [Analytics](https://github.com/killbill/killbill-analytics-plugin) (Java) plugin and the [Stripe](https://github.com/killbill/killbill-stripe-plugin) (Ruby) plugin

To start the installation:

    kpm install kpm.yml

Common configuration options:

* `jvm`: JVM properties
* `killbill`: Kill Bill properties
* `plugins_dir`: OSGI bundles and plugins base directory
* `webapp_path`: path for the Kill Bill war (if specified, Tomcat isn't downloaded)

There are many more options you can specify. Take a look at the configuration file used in the [Docker](https://github.com/killbill/killbill-cloud/blob/master/docker/templates/killbill/latest/kpm.yml.erb) image for example.

### Custom Downloads

You can also download specific versions/artifacts directly with the following commands -- bypassing the kpm.yml file:

* `kpm pull_kaui_war <version>`
* `kpm pull_kb_server_war <version>`
* `kpm install_ruby_plugin plugin-key <kb-version>`
* `kpm install_java_plugin plugin-key <kb-version>`

For more details see `kpm help`.

### Dev Mode

If you are a developer and either modifying an existing plugin or creating a new plugin, KPM can be used to install the code of your plugin. Before we look at KPM commands, make sure you read the [Plugin Development Documentation](http://docs.killbill.io/0.16/plugin_development.html).

Let 's assume we are modifying the code for the (ruby) cybersource plugin. You would have to first build the plugin package, and then you could use KPM to install the plugin. We suggest you specify a `plugin_key` with a namespace `dev:` to make it clear this is not a released version. Also in the case of `ruby`, the package already contains all the directory structure including the version, so only the location of the `tar.gz` needs to be specified.

```
> kpm install_ruby_plugin 'dev:cybersource' --from-source-file="<PATH_TO>/killbill-cybersource-3.3.0.tar.gz"
```

Let 's assume now that we are modifying the code for the (java) adyen plugin. The plugin first needs to be built using the `maven-bundle-plugin` to produce the OSGI jar under the `target` directory. Then, this `jar` can be installed but here we also need to specify a version since the archive does not embed any filesystem structure but only contains the binary (jar). The same applies with regard to the `plugin_key` where we suggest to specify a namespace `dev:`.

```
> kpm install_java_plugin 'dev:adyen' --from-source-file="<PATH_TO>/adyen-plugin-0.3.2-SNAPSHOT.jar" --version="0.3.2"
```

The command `kpm inspect` can be used to see what has been installed. In the case of `dev` plugin most info related to `GROUP ID`, `ARTIFACT ID`, `PACKAGING` and `SHA1` will be missing because no real download occured.


Finally, when it is time to use a released version of a plugin, we first recommend to uninstall the `dev` version, by using the `kpm uninstall` command and using the `plugin_key` and then installing the released version. For instance the following sequence could happen:

```
> kpm inspect
___________________________________________________________________________________________________________________________
|          PLUGIN NAME |      PLUGIN KEY | TYPE | GROUP ID | ARTIFACT ID | PACKAGING | VERSIONS sha1=[], def=(*), del=(x) |
___________________________________________________________________________________________________________________________
| killbill-cybersource | dev:cybersource | ruby |      ??? |         ??? |       ??? |                      3.3.0[???](*) |
|                adyen |       dev:adyen | java |      ??? |         ??? |       ??? |                      0.3.2[???](*) |
___________________________________________________________________________________________________________________________

> kpm uninstall 'dev:cybersource'
Removing the following versions of the killbill-cybersource plugin: 3.3.0
Done!

> kpm inspect

_____________________________________________________________________________________________________________
| PLUGIN NAME | PLUGIN KEY | TYPE | GROUP ID | ARTIFACT ID | PACKAGING | VERSIONS sha1=[], def=(*), del=(x) |
_____________________________________________________________________________________________________________
|       adyen |  dev:adyen | java |      ??? |         ??? |       ??? |                      0.3.2[???](*) |
_____________________________________________________________________________________________________________

> kpm install_ruby_plugin cybersource
[...]

> kpm inspect
_______________________________________________________________________________________________________________________________________________________
|          PLUGIN NAME |  PLUGIN KEY | TYPE |                          GROUP ID |        ARTIFACT ID | PACKAGING | VERSIONS sha1=[], def=(*), del=(x) |
_______________________________________________________________________________________________________________________________________________________
| killbill-cybersource | cybersource | ruby | org.kill-bill.billing.plugin.ruby | cybersource-plugin |    tar.gz |                 4.0.2[e0901f..](*) |
|                adyen |   dev:adyen | java |                               ??? |                ??? |       ??? |                      0.3.2[???](*) |
_______________________________________________________________________________________________________________________________________________________

```
### Test required setups

There are 3 suites of tests for KPM (see `rake -T`):

* `rake test:spec` : Fast suite of unit tests
* `rake test:remote:spec` : Test suite that relies on maven artifacts
* `rake test:mysql:spec` : Test suite that requires an instance of Kill Bill server running and a properly setup database

#### KPM Unit test

Unit tests don't require any third party system or configuration.

#### KPM remote test

Test suite that verifies the following:\

* KPM `install` command by pulling artifacts from maven repository
* KPM `migration` command. This requires setting the `TOKEN` system property with a valid GITHUB api token.

#### KPM mysql test

Test suite that requires an instance of `mysql` running and verifies the following:

* KPM `account` command: The `account_spec.yml` file needs to be modified with correct credentials and user must have correct privileges; also the database schema must not exist.
In addition, one must start an instance of a Kill Bill server

## Internals

### Plugin Keys

In the `kpm.yml` example provided above, the plugins are named using their `pluginKey` (the value for the `name` in the  `kpm.yml`) . The `pluginKey` is the identifier  for the plugin:
* For plugins maintained by the Kill Bill team, this identifier matches the key in the [file based repository](https://github.com/killbill/killbill-cloud/blob/master/kpm/lib/kpm/plugins_directory.yml) of well-known plugins
* For other plugins, this key is either specified when installing the plugin through api call, or default to the `pluginName`. For more information, please refer to the Plugin Developer Guide. 

### Caching

KPM relies on the `kpm.yml` file to know what to install, and as it installs the pieces, it keeps track of what was installed so that if it is invoked again, it does not download again the same binaries. The generic logic associated with that file is the following:

1. When installing a binary (`war`, `jar`, `tar.gz`..), KPM will download both the binary and the `sha1` from the server, compute the `sha1` for the binary and compare the two (verify that binary indeed matches its remote `sha1`). Then, binary is installed and `sha1.yml` file is updated. The `sha1` entry in that `sha1.yml` file will now represent the local `sha1` version (note that for `tar.gz` binaries which have been uncompressed, the local `sha1` is not anymore easily recomputable).
2. When attempting to download again the same binary, KPM will compare the value in the `sha1.yml` and the one on the remote server and if those match, it will not download the binary again.

There are some non standard scenario that could occur in case of users tampering with the data (or remove server unavailable):

* Remote `sha1` is not available: Binary will be downloaded again (and no `sha1` check can be performed)
* `sha1.yml` does not exist:  Binary will be downloaded again 
* `sha1` entry in the `sha1.yml` exists but has the special value `SKIP` :  Binary will *not* be downloaded again 
* Binary does not exist on the file system (or has been replaced with something else): KPM will ignore. Note that correct way to remove plugins is to use the `KPM uninstall` command.


Note that you can override that behavior with the `--force-download` switch.

