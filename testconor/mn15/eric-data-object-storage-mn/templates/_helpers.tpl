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
{{- $globalDefaults := merge $globalDefaults (dict "fsGroup" (dict "manual" "" ) ) -}}
{{- $globalDefaults := merge $globalDefaults (dict "fsGroup" (dict "namespace" "" ) ) -}}
{{- $globalDefaults := merge $globalDefaults (dict "log" (dict "outputs" (list "k8sLevel") ) ) -}}
{{- $globalDefaults := merge $globalDefaults (dict "internalIPFamily" "") -}}
{{- if .Values.global }}
   {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
{{- else }}
   {{- $globalDefaults | toJson -}}
{{- end }}
{{- end }}

{{/* File names of trust and keystore files.. */}}
{{- define "eric-data-object-storage-mn.security.tls.caName" }}
  {{- "cacertbundle.pem" -}}
{{- end }}
{{- define "eric-data-object-storage-mn.security.tls.certName" }}
  {{- "cert.pem" -}}
{{- end }}
{{- define "eric-data-object-storage-mn.security.tls.keyName" }}
  {{- "key.pem" -}}
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

{{/* To simplify registry url access
Set image registry url based on precedence local(imageCredentials.registry.url),
global(.global.registry.url) values.
Additionally, if repoPath is configured, add it to the url
*/}}
{{- define "eric-data-object-storage-mn.imageRegistryUrl" -}}
{{- if .Values.imageCredentials.registry.url -}}
    {{- $url := .Values.imageCredentials.registry.url -}}
    {{- $repoPath := .Values.imageCredentials.repoPath -}}
    {{- if $repoPath -}}
        {{- printf "%s/%s" $url $repoPath -}}
    {{- else -}}
        {{- $url -}}
    {{- end -}}
{{- else -}}
    {{- $g := fromJson (include "eric-data-object-storage-mn.global" .) -}}
    {{- $url := $g.registry.url -}}
    {{- $repoPath := .Values.imageCredentials.repoPath -}}
    {{- if $repoPath -}}
        {{- printf "%s/%s" $url $repoPath -}}
    {{- else -}}
        {{- $url -}}
    {{- end -}}
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

{{/*
Setup required by DR-D1123-123
*/}}
{{- define "eric-data-object-storage-mn.fsGroup.coordinated" -}}
{{- $global := fromJson (include "eric-data-object-storage-mn.global" .) -}}
    {{- if $global.fsGroup -}}
        {{- if $global.fsGroup.manual -}}
            {{ $global.fsGroup.manual -}}
        {{- else -}}
            {{- if $global.fsGroup.namespace -}}
            {{- else -}}
            10000
            {{- end -}}
        {{- end -}}
    {{- else -}}
        10000
    {{- end -}}
{{- end -}}

{{/*
Setup required by DR-D1125-018-AD
*/}}
{{- define "eric-data-object-storage-mn.IPFamily" -}}
{{- $global := fromJson (include "eric-data-object-storage-mn.global" .) -}}
{{- if $global.internalIPFamily -}}
    ipFamilies: [{{ $global.internalIPFamily | quote }}]  # ipFamilies was introduced in K8s v1.20
{{- end }}
{{- end }}

{{/*
Get osmn image path
Required by DR-D1121-067
*/}}
{{- define "eric-data-object-storage-mn.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.osmn.registry -}}
    {{- $repoPath := $productInfo.images.osmn.repoPath -}}
    {{- $name := $productInfo.images.osmn.name -}}
    {{- $tag := $productInfo.images.osmn.tag -}}

    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.osmn -}}
            {{- if .Values.imageCredentials.osmn.registry -}}
                {{- if .Values.imageCredentials.osmn.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.osmn.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.osmn.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.osmn.repoPath -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}

    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}
*/}}

{{/*
Get init image path
Required by DR-D1121-067
*/}}
{{- define "eric-data-object-storage-mn-init.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.init.registry -}}
    {{- $repoPath := $productInfo.images.init.repoPath -}}
    {{- $name := $productInfo.images.init.name -}}
    {{- $tag := $productInfo.images.init.tag -}}

    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.init -}}
            {{- if .Values.imageCredentials.init.registry -}}
                {{- if .Values.imageCredentials.init.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.init.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.init.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.init.repoPath -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}

    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}
*/}}

{{/*
Get bra image path
Required by DR-D1121-067
*/}}
{{- define "eric-data-object-storage-mn-bra.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.bra.registry -}}
    {{- $repoPath := $productInfo.images.bra.repoPath -}}
    {{- $name := $productInfo.images.bra.name -}}
    {{- $tag := $productInfo.images.bra.tag -}}

    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.bra -}}
            {{- if .Values.imageCredentials.bra.registry -}}
                {{- if .Values.imageCredentials.bra.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.bra.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.bra.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.bra.repoPath -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}

    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}
*/}}

{{/*
Create annotation for the product information (DR-D1121-064, DR-D1121-067)
*/}}
{{- define "eric-data-object-storage-mn.product-info" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end}}
