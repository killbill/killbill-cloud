# Kill Bill Helm chart

Deploys [Kill Bill](https://killbill.io), Kaui (the admin UI) and a database on Kubernetes.
The database is one of:

- a bundled MariaDB (default) or PostgreSQL, with the Kill Bill and Kaui schemas already created;
- an existing MySQL, MariaDB or PostgreSQL server (`database.external`).

## Install

```bash
helm install killbill ./helm/killbill
```

The notes printed after the install show how to reach Kaui and the Kill Bill API.
The first start can take a few minutes.

To set your own passwords:

```bash
helm install killbill ./helm/killbill \
  --set killbill.adminPassword=<admin password> \
  --set database.password=<database password>
```

To use a Secret you manage yourself instead, create it with the keys `db-password`, `admin-password` and `kaui-secret-key-base` (a long random string that signs Kaui sessions), then set `existingSecret`:

```bash
kubectl create secret generic killbill-passwords \
  --from-literal=db-password=<database password> \
  --from-literal=admin-password=<admin password> \
  --from-literal=kaui-secret-key-base=$(openssl rand -hex 64)
helm install killbill ./helm/killbill --set existingSecret=killbill-passwords
```

## Database

Bundled PostgreSQL instead of MariaDB:

```bash
helm install killbill ./helm/killbill --set database.type=postgresql
```

Existing database server. The Kill Bill and Kaui schemas must already exist in it:

```bash
helm install killbill ./helm/killbill \
  --set database.type=postgresql \
  --set database.external.enabled=true \
  --set database.external.host=<host> \
  --set database.external.user=<user> \
  --set database.password=<password> \
  --set database.external.jdbcParameters=sslmode=require
```

`jdbcParameters` is optional; managed databases often require SSL.

## Main values

| Value | Default | Description |
|---|---|---|
| `killbill.image.repository` / `tag` | `killbill/killbill` / `0.24.22` | Kill Bill image |
| `killbill.adminPassword` | `password` | Password of the `admin` user, also used to log in to Kaui |
| `killbill.service.port` | `8080` | Kill Bill service port |
| `killbill.extraEnv` | `[]` | Extra environment variables for Kill Bill |
| `killbill.extraVolumes` / `extraVolumeMounts` | `[]` | Extra volumes and mounts for Kill Bill |
| `kaui.image.repository` / `tag` | `killbill/kaui` / `4.0.31` | Kaui image |
| `kaui.service.port` | `9090` | Kaui service port |
| `kaui.secretKeyBase` | `""` | Key that signs Kaui sessions; generated and kept across upgrades when empty (set it when rendering without cluster access, for example with Argo CD) |
| `database.type` | `mariadb` | `mariadb` (also for an external MySQL server) or `postgresql` |
| `database.password` | `killbill` | Database password; for a bundled database, applied on the first install only |
| `database.external.enabled` | `false` | Use an existing database server instead of a bundled one |
| `database.external.host` / `port` / `user` | `""` | Connection to the existing server; the port defaults to 3306 or 5432 |
| `database.external.killbillDatabase` / `kauiDatabase` | `killbill` / `kaui` | Database names on the existing server |
| `database.external.jdbcParameters` | `""` | Extra JDBC URL parameters, for example `sslmode=require` |
| `mariadb.image.repository` / `tag` | `killbill/mariadb` / `0.24` | Bundled MariaDB image |
| `postgresql.image.repository` / `tag` | `killbill/postgresql` / `0.24` | Bundled PostgreSQL image |
| `mariadb.persistence.*` / `postgresql.persistence.*` | `10Gi`, `ReadWriteOnce` | Volume of the bundled database; `storageClass` empty means the cluster default |
| `existingSecret` | `""` | Use your own Secret for the passwords |
| `imagePullSecrets` | `[]` | Secrets for pulling images from a private registry |

See [values.yaml](values.yaml) for all values.

## Notes

- Use a versioned Kill Bill image. The `latest` development image installs plugins on start against a local MySQL and is not supported by this chart.
- Changing a chart-managed password with `helm upgrade` restarts Kill Bill and Kaui so they pick it up. With `existingSecret`, restart them yourself (`kubectl rollout restart`).
- A bundled database runs as a single pod with one volume. It suits evaluation and development.
- `database.password` only takes effect for a bundled database when its volume is empty. Changing it later does not change the password of an existing database.
- The bundled database volume is kept when the release is uninstalled, so billing data is not lost by accident. To delete it, find it with `kubectl get pvc` (its name ends in `-mariadb` or `-postgresql`) and run `kubectl delete pvc <name>`.
