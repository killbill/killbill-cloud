# KPM: the Kill Bill Package Manager

The goal of KPM is to facilitate the installation of Kill Bill, its plugins and Kaui.

kpm can be used interactively to search and download individual artifacts (Kill Bill war, plugins, etc.) or to perform an automatic Kill Bill installation using a configuration file.

## Installation

    gem install kpm

Ruby 2.1+ or JRuby 1.7.11+ is recommended.

## Quick start

The following commands

    mkdir killbill
    cd killbill
    kpm install

will setup Kill Bill, i.e.:

* Tomcat (open-source Java web server) is setup in the `killbill` directory
* The Kill Bill application (war) is installed in the `killbill/webapps` directory
* Default plugins are installed in the `/var/tmp/bundles` directory, among them:
 * `jruby.jar`, required to run Ruby plugins
 * the [KPM plugin](https://github.com/killbill/killbill-kpm-plugin), required to (un-)install plugins at runtime

To start Kill Bill, simply run

    ./bin/catalina.sh run

You can then verify Kill Bill is running by going to http://127.0.0.1:8080/index.html.

## Configuration

You can configure the installation process using a kpm.yml file.

For example:

    killbill:
      version: 0.14.0
      plugins:
        java:
          - name: analytics
        ruby:
          - name: stripe

This instructs kpm to:

* Download Kill Bill version 0.14.0
* Setup the Analytics (Java) plugin and the Stripe (Ruby) plugin

To start the installation:

    kpm install kpm.yml

Common configuration options:

* `jvm`: JVM properties
* `killbill`: Kill Bill properties
* `plugins_dir`: OSGI bundles and plugins base directory
* `webapp_path`: path for the Kill Bill war (if specified, Tomcat isn't downloaded)

There are many more options you can specify. Take a look at the configuration file used in the [Docker](https://github.com/killbill/killbill-cloud/blob/master/docker/templates/killbill/latest/kpm.yml.erb) image for example.

## Internals and Advanced Commands

### Caching

KPM relies on the kpm.yml file to know what to install, and as it installs the pieces it keeps track of what was installed so that if it is invoked again, it does not download again the same binaries:

* For the Kill Bill artifact itself, kpm will first extract the sha1 from the remote repository and compare with the current sha1 installed under the default `webapp_path`; if those are the same, the file is not downloaded again.
* For the plugins, since those are downloaded as an archive (*.tgz) and then decompressed/expanded, kpm will use an internal file, `<plugins_dir>/sha1.yml` to keep track of the sha1 archive. If there is an entry and the sha1 matches, then the file is not downloaded again.

Note that you can override that behavior with the `--force-download` switch.

### Custom Downloads

Note that you can also download specific versions/artifacts directly with the following commands -- bypassing the kpm.yml file:

* `kpm pull_kaui_war <version>`
* `kpm pull_kb_server_war <version>`
* `kpm pull_ruby_plugin <artifact_id>`

For more details see `kpm --help`.
