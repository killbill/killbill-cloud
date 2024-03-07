# killbill/base image

Shared base image with Tomcat, JDK and KPM inside Ubuntu 20.04 LTS. It also contains Ansible and our playbooks from https://github.com/killbill/killbill-cloud.

To build this docker image:

```
docker build -t killbill/base:latest --build-arg KILLBILL_CLOUD_VERSION=<some_branch> .
```

Here `<some_branch>` specifies the branch of the `killbill-cloud` repo that should be [checked-out](https://github.com/killbill/killbill-cloud/blob/05b8447850be6c2f547acef2817d4d31b81a11cd/docker/templates/base/latest/Dockerfile#L61) at build time. If the `KILLBILL_CLOUD_VERSION` argument is not specified, the `master` branch is used.
