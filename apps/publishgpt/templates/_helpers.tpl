{{/*
Expand the name of the chart.
*/}}
{{- define "publishgpt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "publishgpt.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "publishgpt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "publishgpt.labels" -}}
helm.sh/chart: {{ include "publishgpt.chart" . }}
{{ include "publishgpt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "publishgpt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "publishgpt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "publishgpt.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "publishgpt.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Selector labels for frontend
*/}}
{{- define "publishgpt.frontendSelectorLabels" -}}
{{ include "publishgpt.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Selector labels for backend
*/}}
{{- define "publishgpt.backendSelectorLabels" -}}
{{ include "publishgpt.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}
