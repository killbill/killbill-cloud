Utilities to configure and launch Kill Bill
===========================================

Kill Bill at its core is a [web application](https://en.wikipedia.org/wiki/WAR_(file_format)). Deploying it typically involves installing a [Web container](https://en.wikipedia.org/wiki/Web_container), the Kill Bill war, and various Kill Bill plugins, as well as customized configuration files.

To help with this, there are several tools at your disposal:

* [KPM](https://github.com/killbill/killbill-cloud/tree/master/kpm): the Kill Bill Package Manager, a low-level tool to download the Kill Bill war and its plugins.
* [Ansible](https://docs.ansible.com/): an open-source IT Automation tool. We provide [playbooks](https://github.com/killbill/killbill-cloud/tree/master/ansible) to install [Apache Tomcat](https://tomcat.apache.org/), [KPM](https://github.com/killbill/killbill-cloud/tree/master/kpm) and Kill Bill itself (via KPM behind the scenes).
* [Docker](https://docs.docker.com/): an open-source containerization platform. We provide self-contained [images](https://github.com/killbill/killbill-cloud/tree/master/docker) for each version of Kill Bill (images are built using Ansible behind the scenes).

Besides Kill Bill, you will also need to deploy a database and [Kaui](https://github.com/killbill/killbill-admin-ui) (the Kill Bill Admin UI).

To help orchestrate the deployment of these services, you can use:

* [Docker Compose](https://docs.docker.com/compose/): we provide [recipes](https://github.com/killbill/killbill-cloud/tree/master/docker/compose) to spin up Kill Bill and its dependencies. We also maintain recipes to deploy the open-source [Elastic stack](https://www.elastic.co/products) and the open-source [InfluxData stack](https://www.influxdata.com/time-series-platform/) integrated with Kill Bill.
* [Ansible Container](https://docs.ansible.com/ansible-container/getting_started.html): we provide an [orchestration document](https://github.com/killbill/killbill-cloud/tree/master/ansible-container) to help with Kubernetes and OpenShift deployments. *ADVANCED USERS ONLY*

Finally, to deploy Kill Bill in the cloud, you can use:

* Our Docker Compose recipes on any [Docker Machine supported platform](https://docs.docker.com/machine/drivers/).
* [DC/OS](https://dcos.io/): an open-source datacenter operating system. We provide [Marathon app definitions](https://github.com/killbill/killbill-cloud/tree/master/mesos).


Getting started
---------------

To get up and running quickly, we **strongly** recommend using our [Docker Compose recipes](https://github.com/killbill/killbill-cloud/tree/master/docker/compose), which will set up the full Kill Bill stack for you.

If you are not yet familiar with Docker, take a look at the [Get Started with Docker](https://docs.docker.com/get-started/) guide.

