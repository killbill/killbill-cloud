Scripts to launch Kill Bill in the cloud.
========================================

The initial revision focuses on AWS:

Quick start
-----------

Create a directory, e.g. ~/aws. In this directory, you'll need:

* cloud.yml, the AWS config file
* killbill.config, the Kill Bill master config file
* Any other config files required for Kill Bill (e.g. killbill.properties, killbill_catalog.xml or overdue.xml) or its plugins (e.g. klogger.yml)

You can then start your instance via:

```./launcher.rb -i ~/aws -a cloud.yml -k killbill.config```

Assumptions
-----------

User has an aws access with the following:
* aws access_key
* aws secret_key
* private key to ssh to ec2 instances

Scripts
-------
* launcher.rb : master script that drives the installation of the instances and start Kill Bill
* ami_install.sh : bootstrap script to is scp'ed on each ec2 instance to install basic packages
* killbill_install.rb : script that is also scp'ed on the instnaces to download the killbill-server.war and all the required plugins


Configs
-------

launcher.rb takes the following arguments:
* --input_config_dir : location directory from where ALL config files reside
* --aws_config : AWS config file, that lives in input_config_dir
* --killbill_config : Kill Bill master config file, that lives in input_config_dir
* --terminate : a valid path to a file that specifies instances to terminate; if that option is present this is all will happen

Format for AWS config file:
<pre>
 :aws:
    :ec2:
        :ami: "the_sane_ami"
        :security_group: the_security_group"
        :instance_type: "the_instance_type"
        :availability_zone: "the_aws_availabilit_zone"
        :key_name: "the_amazon_ec2_key_pair"
        :access_key: "the_aws_access_key"
        :secret_key: "the_aws_secret_key"
        :ssh_private_key_path: "the SSH private key used to connect to running instances"

    :rds:
        :endpoint: "the_rds_endpoint"
        :database_name: "killbill"
        :user_name: "the_db_user_name"
        :password: "the_db_pwd"

</pre>

Format for the Kill Bill config:

<pre>
:killbill:
 :version: 0.1.80
 :config: killbill.properties
 :catalog: killbill_catalog.xml 
 :overdue: overdue.xml
 :invoice_template: blah.template

:plugins: 
 :paypal-express-plugin:
   :config: paypal_express.yml

 :logging-plugin:
   :config: klogger.yml
</pre>

