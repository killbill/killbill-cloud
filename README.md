Scripts to launch Kill Bill in the cloud.
========================================


The initial revision focuses on AWS:

Assumptions
-------------

User has an aws access with the following:
* aws access_key
* aws secret_key
* private key to shh to e2 instances

Scripts
-------
* launcher.rb : master script that drives the installation of the instances and start Kill Bill
* ami_install.sh : bootstrap script to is scp'ed on each ec2 instance to install basic packages
* killbill_install.rb : script that is also scp'ed on the instnaces to download the killbill-server.war and all the required plugins


Configs
--------

launcher.rb takes the following arguments:
* --input_config_dir : location directory from where ALL config files reside
* --aws_config : AWS config file, that lives in input_config_dir
* --killbill_config : Kill Bill master config file
* --terminate : a valid path to a file that specifies instances to terminate; if that option is present this is all will happen

Format for AWS config file:
<pre>
 :aws:
    :ec2:
        :ami: "the_sane_ami"
        :security_group: the_security_group"
        :instance_type: "the_instnace_type"
        :availability_zone: "the_aws_availabilit_zone"
        :key_name: "a string to tag the running instances"
        :access_key: "the_aws_Access_key"
        :secret_key: "the_aws_secret_key"
        :ssh_private_key_path: "the SSH private key used to connect to running instances"

    :rds:
        :endpoint: "the_rds_endpoint"
        :database_name: "killbill"
        :user_name: "the_db_user_name"
        :password: "the_db_pwd"

</pre>

Format for the Kill Bill config

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

