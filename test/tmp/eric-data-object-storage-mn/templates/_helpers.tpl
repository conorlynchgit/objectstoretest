{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-object-storage-mn.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}

{{ define "eric-data-object-storage-mn.global" }}
{{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
{{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
{{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "pullSecret")) -}}
{{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se")) -}}
{{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
{{- $globalDefaults := merge $globalDefaults (dict "serviceNames" (dict "ctrl" (dict "bro" "eric-ctrl-bro"))) -}}
{{- $globalDefaults := merge $globalDefaults (dict "servicePorts" (dict "ctrl" (dict "bro" 3000))) -}}
{{- if .Values.global }}
   {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
{{- else }}
   {{- $globalDefaults | toJson -}}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-data-object-storage-mn.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Semi-colon separated list of backup types
*/}}
{{- define "eric-data-object-storage-mn.backupTypes" }}
{{- range $i, $e := .Values.brAgent.backupTypeList -}}
{{- if eq $i 0 -}}{{- printf " " -}}{{- else -}}{{- printf ";" -}}{{- end -}}{{- . -}}
{{- end -}}
{{- end -}}

{{/*
Create version
*/}}
{{- define "eric-data-object-storage-mn.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-data-object-storage-mn.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Determine service account name for deployment or statefulset.
*/}}
{{- define "eric-data-object-storage-mn.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "eric-data-object-storage-mn.name" .) .Values.serviceAccount.name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the Docker image.
*/}}
{{- define "eric-data-object-storage-mn.image" -}}
{{- $global := fromJson (include "eric-data-object-storage-mn.global" .) -}}
{{- if .Values.imageCredentials.registry.url -}}
{{- printf "%s/%s/%s:%s" .Values.imageCredentials.registry.url .Values.imageCredentials.repoPath .Values.images.minio.name .Values.images.minio.tag -}}
{{- else -}}
{{- printf "%s/%s/%s:%s" $global.registry.url .Values.imageCredentials.repoPath .Values.images.minio.name .Values.images.minio.tag -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the init container Docker image.
*/}}
{{- define "eric-data-object-storage-mn.initImage" -}}
{{- $global := fromJson (include "eric-data-object-storage-mn.global" .) -}}
{{- if .Values.imageCredentials.registry.url -}}
{{- printf "%s/%s/%s:%s" .Values.imageCredentials.registry.url .Values.imageCredentials.repoPath .Values.images.init.name .Values.images.init.tag -}}
{{- else -}}
{{- printf "%s/%s/%s:%s" $global.registry.url .Values.imageCredentials.repoPath .Values.images.init.name .Values.images.init.tag -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the bra container Docker image.
*/}}
{{- define "eric-data-object-storage-mn.braImage" -}}
{{- $global := fromJson (include "eric-data-object-storage-mn.global" .) -}}
{{- if .Values.imageCredentials.registry.url -}}
{{- printf "%s/%s/%s:%s" .Values.imageCredentials.registry.url .Values.imageCredentials.repoPath .Values.images.bra.name .Values.images.bra.tag -}}
{{- else -}}
{{- printf "%s/%s/%s:%s" $global.registry.url .Values.imageCredentials.repoPath .Values.images.bra.name .Values.images.bra.tag -}}
{{- end -}}
{{- end -}}

{{/*
Create image pull secrets.
*/}}
{{- define "eric-data-object-storage-mn.pullSecrets" -}}
{{- $global := fromJson (include "eric-data-object-storage-mn.global" .) -}}
{{- if .Values.imageCredentials.pullSecret -}}
{{- print .Values.imageCredentials.pullSecret -}}
{{- else if $global.pullSecret -}}
{{- print $global.pullSecret -}}
{{- end -}}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}

{{ define "eric-data-object-storage-mn.nodeSelector" }}
  {{- $global := fromJson (include "eric-data-object-storage-mn.global" .) }}
  {{- if .Values.nodeSelector -}}
    {{- range $key, $localValue := .Values.nodeSelector -}}
      {{- if hasKey $global.nodeSelector $key -}}
          {{- $globalValue := index $global.nodeSelector $key -}}
          {{- if ne $globalValue $localValue -}}
            {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
         {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- toYaml (merge $global.nodeSelector .Values.nodeSelector) | trim -}}
  {{- else -}}
    {{- toYaml $global.nodeSelector | trim -}}
  {{- end -}}
{{ end }}

