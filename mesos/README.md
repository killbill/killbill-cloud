# Kill Bill on DC/OS

```
# Install the database
dcos marathon app add db-marathon.json
dcos task log --follow db

# Install Kill Bill
dcos marathon app add kb-marathon.json
dcos task log --follow killbill

# Install public load balancer for Kaui
dcos package install --options=marathon-lb-external.json marathon-lb

# Install Kaui
dcos marathon app add kaui-marathon.json
dcos task log --follow kaui

# Find public node IP
for id in $(dcos node --json | jq --raw-output '.[] | select(.attributes.public_ip == "true") | .id'); do dcos node ssh --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --mesos-id=$id "curl -s ifconfig.co" ; done 2>/dev/null
```

Go to <public-node-ip>:10080 to log-in to Kaui.

## VIPs

* Database: `killbill-db.marathon.l4lb.thisdcos.directory:3306`
* Kill Bill: `killbill.marathon.l4lb.thisdcos.directory:3306`
* Kaui: `http://marathon-lb-external.marathon.mesos:10080`