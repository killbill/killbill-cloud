{{/*
Expand the name of the chart.
*/}}
{{- define "killbill.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
The Kill Bill server resources use this name.
*/}}
{{- define "killbill.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Name of the Kaui resources.
*/}}
{{- define "killbill.kauiName" -}}
{{- printf "%s-kaui" (include "killbill.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Database engine, validated: "mariadb" or "postgresql".
*/}}
{{- define "killbill.dbType" -}}
{{- $type := .Values.database.type }}
{{- if not (or (eq $type "mariadb") (eq $type "postgresql")) }}
{{- fail (printf "database.type must be \"mariadb\" or \"postgresql\", got %q" $type) }}
{{- end }}
{{- $type }}
{{- end }}

{{/*
Engine of the bundled database, or empty when an external database is used.
*/}}
{{- define "killbill.bundledDb" -}}
{{- if not .Values.database.external.enabled }}
{{- include "killbill.dbType" . }}
{{- end }}
{{- end }}

{{/*
Name of the bundled database resources. It is also the database host name.
*/}}
{{- define "killbill.dbName" -}}
{{- printf "%s-%s" (include "killbill.fullname" .) (include "killbill.dbType" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Database host.
*/}}
{{- define "killbill.dbHost" -}}
{{- if .Values.database.external.enabled }}
{{- required "database.external.host is required when database.external.enabled is true" .Values.database.external.host }}
{{- else }}
{{- include "killbill.dbName" . }}
{{- end }}
{{- end }}

{{/*
Database port: the external port (or the engine's default), or the bundled database's service port.
*/}}
{{- define "killbill.dbPort" -}}
{{- $postgresql := eq (include "killbill.dbType" .) "postgresql" }}
{{- if .Values.database.external.enabled }}
{{- .Values.database.external.port | default (ternary 5432 3306 $postgresql) }}
{{- else }}
{{- ternary .Values.postgresql.service.port .Values.mariadb.service.port $postgresql }}
{{- end }}
{{- end }}

{{/*
Database user: the external user, or the bundled database's admin user.
*/}}
{{- define "killbill.dbUser" -}}
{{- if .Values.database.external.enabled }}
{{- required "database.external.user is required when database.external.enabled is true" .Values.database.external.user }}
{{- else }}
{{- ternary "postgres" "root" (eq (include "killbill.dbType" .) "postgresql") }}
{{- end }}
{{- end }}

{{/*
JDBC URLs of the Kill Bill and Kaui databases.
*/}}
{{- define "killbill.killbillJdbcUrl" -}}
{{- $database := ternary .Values.database.external.killbillDatabase "killbill" .Values.database.external.enabled }}
{{- printf "jdbc:%s://%s:%s/%s" (ternary "postgresql" "mysql" (eq (include "killbill.dbType" .) "postgresql")) (include "killbill.dbHost" .) (include "killbill.dbPort" .) $database }}
{{- end }}

{{- define "killbill.kauiJdbcUrl" -}}
{{- $database := ternary .Values.database.external.kauiDatabase "kaui" .Values.database.external.enabled }}
{{- printf "jdbc:%s://%s:%s/%s" (ternary "postgresql" "mysql" (eq (include "killbill.dbType" .) "postgresql")) (include "killbill.dbHost" .) (include "killbill.dbPort" .) $database }}
{{- end }}

{{/*
Name of the Secret holding the passwords.
*/}}
{{- define "killbill.secretName" -}}
{{- default (include "killbill.fullname" .) .Values.existingSecret }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "killbill.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "killbill.labels" -}}
helm.sh/chart: {{ include "killbill.chart" . }}
{{ include "killbill.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "killbill.selectorLabels" -}}
app.kubernetes.io/name: {{ include "killbill.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
