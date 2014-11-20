KPM: the Kill Bill Package Manager
==================================

The goal of KPM is to facilitate the installation of Kill Bill and its plugins.

kpm can be used interactively to search and download individual artifacts (Kill Bill war, plugins, etc.) or to perform an automatic Kill Bill installation using a configuration file.

Installation
------------

   gem install kpm

Ruby 2.1+ or JRuby 1.7.11+ is recommended.

Quick start
-----------

Create a kpm.yml file as follows:

    killbill:
      version: 0.12.1
      webapp_path: /opt/tomcat/webapps/ROOT
      plugins_dir: /var/tmp/bundles
      plugins:
        java:
          - name: analytics-plugin
            version: 0.7.2
        ruby:
          - name: stripe-plugin
            version: 0.2.1
    kaui:
      version: LATEST
      webapp_path: /opt/tomcat/webapps/kaui

This instructs kpm to:
* Download the Kill Bill war (version 0.12.1) and install it as `/opt/tomcat/webapps/ROOT`
* Setup the Analytics (Java) plugin (version 0.7.2) and the Stripe (Ruby) plugin (version 0.2.1) under `/var/tmp/bundles`
* Download the latest Kaui war and install it as `/opt/tomcat/webapps/kaui`

To start the installation:

   kpm install kpm.yml

To help you with discovery of plugins, you can run

   kpm search_for_plugins

This will list available (official) plugins. We maintain a list of recommended versions to use at https://github.com/killbill/killbill-cloud/blob/master/kpm/lib/kpm/plugins_directory.yml.
