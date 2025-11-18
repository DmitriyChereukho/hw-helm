{{- define "muffin-currency.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "muffin-currency.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "muffin-currency.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}