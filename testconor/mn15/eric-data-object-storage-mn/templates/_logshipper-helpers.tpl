{{/*
Template of Log Shipper sidecar
Version: 6.0.0-17
*/}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{- define "eric-data-object-storage-mn.logshipper-global" -}}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $globalDefaults := dict "timezone" "UTC" -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "tls" (dict "enabled" true))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent" )) -}}
  {{- if $productInfo -}}
    {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" $productInfo.images.logshipper.registry )) -}}
  {{- else -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se" )) -}}
  {{- end -}}
  {{- if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{- else -}}
    {{- $globalDefaults | toJson -}}
  {{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-data-object-storage-mn.logshipper-service-fullname" -}}
{{- if .Values.fullnameOverride -}}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-object-storage-mn.logshipper-name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create kubernetes.io name and version
*/}}
{{- define "eric-data-object-storage-mn.logshipper-labels" }}
app.kubernetes.io/name: {{ include "eric-data-object-storage-mn.name" . | quote }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}


{{/*
Log Shipper sidecar container spec
*/}}
{{- define "eric-data-object-storage-mn.logshipper-container" -}}
{{- $g := fromJson (include "eric-data-object-storage-mn.logshipper-global" .) }}
{{- $default := fromJson (include "eric-data-object-storage-mn.logshipper-default-value" .) }}
- name: "logshipper"
  imagePullPolicy: {{ or $default.imageCredentials.logshipper.registry.imagePullPolicy $g.registry.imagePullPolicy }}
  image: "{{ template "eric-data-object-storage-mn-logshipper.imagePath" . }}"
  securityContext:
    allowPrivilegeEscalation: false
    privileged: false
    readOnlyRootFilesystem: false
    runAsNonRoot: true
    capabilities:
      drop:
        - "all"
  env:
  - name: TZ
    value: {{ $g.timezone | quote }}
  - name: LOG_LEVEL
    value: {{ $default.log.logshipper.level | quote | upper }}
  - name: DEPLOYMENT_TYPE
    value: "SIDECAR"
  - name: TLS_ENABLED
  {{- if $g.security.tls.enabled }}
    value: "true"
  {{- else }}
    value: "false"
  {{- end }}
  - name: RUN_AND_EXIT
  {{- if $default.logshipper.runAndExit }}
    value: "true"
  {{- else }}
    value: "false"
  {{- end }}
  - name : SHUTDOWN_DELAY
    value: {{ $default.logshipper.shutdownDelay | quote }}
  - name: LOG_PATH
    value: {{ $default.logshipper.storagePath | quote }}
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
  - name: POD_UID
    valueFrom:
      fieldRef:
        fieldPath: metadata.uid
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: SERVICE_ID
    value: {{ include "eric-data-object-storage-mn.logshipper-service-fullname" . }}
  - name: CONTAINER_NAME
    value: logshipper
  livenessProbe:
    exec:
      command:
        - "/bin/bash"
        - "-c"
        - "[[ ! -f {{ $default.logshipper.storagePath }}/data/started ]] || exec pgrep -l filebeat"
    initialDelaySeconds: {{ $default.livenessProbe.logshipper.initialDelaySeconds }}
    timeoutSeconds: {{ $default.livenessProbe.logshipper.timeoutSeconds }}
    periodSeconds: {{ $default.livenessProbe.logshipper.periodSeconds }}
    successThreshold: {{ $default.livenessProbe.logshipper.successThreshold }}
    failureThreshold: {{ $default.livenessProbe.logshipper.failureThreshold }}
  resources:
    limits:
      {{- if $default.resources.logshipper.limits.cpu }}
      cpu: {{ $default.resources.logshipper.limits.cpu  | quote }}
      {{- end }}
      {{- if $default.resources.logshipper.limits.memory }}
      memory: {{ $default.resources.logshipper.limits.memory  | quote }}
      {{- end }}
      {{- if index $default.resources.logshipper.limits "ephemeral-storage" }}
        ephemeral-storage: {{ index $default.resources.logshipper.limits "ephemeral-storage"  | quote }}
      {{- end }}
    requests:
      {{- if $default.resources.logshipper.requests.cpu }}
      cpu: {{ $default.resources.logshipper.requests.cpu  | quote }}
      {{- end }}
      {{- if $default.resources.logshipper.requests.memory }}
      memory: {{ $default.resources.logshipper.requests.memory  | quote }}
      {{- end }}
      {{- if index $default.resources.logshipper.requests "ephemeral-storage" }}
        ephemeral-storage: {{ index $default.resources.logshipper.requests "ephemeral-storage"  | quote }}
      {{- end }}
  volumeMounts:
  - name: "eric-log-shipper-storage-path"
    mountPath: {{ $default.logshipper.storagePath | quote }}
  - name: "{{ include "eric-data-object-storage-mn.logshipper-service-fullname" . }}-logshipper-cfg"
    mountPath: "/etc/filebeat/filebeat.yml"
    subPath: "filebeat.yml"
    readOnly: true
  {{- if $g.security.tls.enabled }}
  - name: "server-ca-certificate"
    mountPath: "/run/secrets/ca-certificates/"
    readOnly: true
  - name: "lt-client-cert"
    mountPath: "/run/secrets/certificates/"
    readOnly: true
  {{- end }}
{{- end -}}

{{/*
Share logs volume mount path
*/}}
{{- define "eric-data-object-storage-mn.logshipper-storage-path" }}
{{- $default := fromJson (include "eric-data-object-storage-mn.logshipper-default-value" .) }}
- name: "eric-log-shipper-storage-path"
  mountPath: {{ $default.logshipper.storagePath | quote }}
{{- end -}}


{{/*
Log Shipper sidecar related volumes
*/}}
{{- define "eric-data-object-storage-mn.logshipper-volume" -}}
{{- $g := fromJson (include "eric-data-object-storage-mn.logshipper-global" .) }}
{{- $default := fromJson (include "eric-data-object-storage-mn.logshipper-default-value" .) }}
- name: "eric-log-shipper-storage-path"
  emptyDir:
  {{- if $default.logshipper.storageAllocation }}
    sizeLimit: {{ $default.logshipper.storageAllocation | quote }}
  {{- end }}
  {{- if $default.logshipper.storageMedium }}
    medium: {{ $default.logshipper.storageMedium | quote }}
    {{- end }}
- name: "{{ include "eric-data-object-storage-mn.logshipper-service-fullname" . }}-logshipper-cfg"
  configMap:
    name: "{{ include "eric-data-object-storage-mn.logshipper-service-fullname" . }}-logshipper-cfg"
{{- if $g.security.tls.enabled }}
- name: "server-ca-certificate"
  secret:
    secretName: "eric-sec-sip-tls-trusted-root-cert"
    optional: true
- name: "lt-client-cert"
  secret:
    secretName: "{{ include "eric-data-object-storage-mn.logshipper-service-fullname" . }}-lt-client-cert"
    optional: true
{{- end }}
{{- end -}}

{{/*
ClientCertificate Resource declaration file for TLS between logshipper and logtransformer
*/}}
{{- define "eric-data-object-storage-mn.logshipper-tls-cert-lt-client" -}}
{{- $default := fromJson (include "eric-data-object-storage-mn.logshipper-default-value" .) -}}
{{- $g := fromJson (include "eric-data-object-storage-mn.logshipper-global" .) -}}
{{- if $g.security.tls.enabled -}}
apiVersion: "siptls.sec.ericsson.com/v1"
kind: "InternalCertificate"
metadata:
  name: "{{ include "eric-data-object-storage-mn.logshipper-service-fullname" . }}-lt-client-cert"
  labels:
    {{- include "eric-data-object-storage-mn.logshipper-labels" . | indent 4 }}
  annotations:
    {{- include "eric-data-object-storage-mn.product-info" . | indent 4 }}
spec:
  kubernetes:
    generatedSecretName: "{{ include "eric-data-object-storage-mn.logshipper-service-fullname" . }}-lt-client-cert"
    certificateName: "clicert.pem"
    privateKeyName: "cliprivkey.pem"
  certificate:
    subject:
      cn: {{ include "eric-data-object-storage-mn.logshipper-service-fullname" . | quote }}
    issuer:
      reference: "{{ $default.logshipper.logtransformer.host }}-input-ca-cert"
    extendedKeyUsage:
      tlsClientAuth: true
      tlsServerAuth: false
{{- end -}}
{{- end -}}

{{- define "eric-data-object-storage-mn.logshipper-default-value" -}}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $default := dict "livenessProbe" (dict "logshipper" (dict "initialDelaySeconds" 1 )) -}}
  {{- $default := merge $default (dict "livenessProbe" (dict "logshipper" (dict "timeoutSeconds" 10 ))) -}}
  {{- $default := merge $default (dict "livenessProbe" (dict "logshipper" (dict "periodSeconds" 10 ))) -}}
  {{- $default := merge $default (dict "livenessProbe" (dict "logshipper" (dict "successThreshold" 1 ))) -}}
  {{- $default := merge $default (dict "livenessProbe" (dict "logshipper" (dict "failureThreshold" 3 ))) -}}
  {{- $default := merge $default (dict "imageCredentials" (dict "logshipper" (dict "registry" (dict "imagePullPolicy" )))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "runAndExit" false )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "shutdownDelay" 10 )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "storagePath" "/logs" )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "storageMedium" "" )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "harvester" (dict "closeTimeout" "5m" ))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "harvester" (dict "logData" (dict)))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "logtransformer" (dict "host" "eric-log-transformer" ))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "logplane" "adp-app-logs")) -}}
  {{- $default := merge $default (dict "log" (dict "logshipper" (dict "level" "info" ))) -}}
  {{- mergeOverwrite $default .Values | toJson -}}
{{- end -}}

{{/*
Get logshipper image path
Required by DR-D1121-067
*/}}
{{- define "eric-data-object-storage-mn-logshipper.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.logshipper.registry -}}
    {{- $repoPath := $productInfo.images.logshipper.repoPath -}}
    {{- $name := $productInfo.images.logshipper.name -}}
    {{- $tag := $productInfo.images.logshipper.tag -}}

    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.logshipper -}}
            {{- if .Values.imageCredentials.logshipper.registry -}}
                {{- if .Values.imageCredentials.logshipper.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.logshipper.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.logshipper.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.logshipper.repoPath -}}
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

