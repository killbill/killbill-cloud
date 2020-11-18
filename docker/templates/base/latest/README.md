# killbill/base image

The base image contains Ansible and our playbooks from https://github.com/killbill/killbill-cloud.

By default, the latest version of `master` is checked-out at build time, but this can be configured through the `KILLBILL_CLOUD_VERSION` build argument, e.g.:

```
docker build -t killbill/base:latest --build-arg KILLBILL_CLOUD_VERSION=<some_branch> .
```
