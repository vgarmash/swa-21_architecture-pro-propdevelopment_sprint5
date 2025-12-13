#!/bin/bash
set -euo pipefail

INPUT=${1:-audit.log}

jq -R '
  fromjson?
  | select(.apiVersion == "audit.k8s.io/v1" and .kind == "Event")
  | select(
      (.objectRef.resource == "secrets" and .verb == "get")
      or (.objectRef.subresource == "exec" and (.verb == "create" or .verb == "connect"))
      or (.objectRef.resource == "pods"
          and (.requestObject.spec.containers[]?.securityContext?.privileged // false == true))
      or (.objectRef.resource == "rolebindingsrolebindings"
          and (.requestObject.roleRef.name // "" == "cluster-admin"))
      or ((.requestURI // "") | contains("audit-policy"))
      or ((.objectRef.name // "") == "audit-policy")
    )
' "$INPUT" > audit-extract.json

echo "Готово"

