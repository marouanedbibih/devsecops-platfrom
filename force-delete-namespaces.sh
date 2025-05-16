#!/bin/bash

# List of namespaces to force-delete
namespaces=(
  cattle-fleet-clusters-system
  cattle-fleet-local-system
  cattle-fleet-system
  cattle-global-data
  cattle-global-nt
  cattle-impersonation-system
  cattle-provisioning-capi-system
  cattle-system
  cattle-ui-plugin-system
)

echo "⏳ Forcing deletion of terminating namespaces..."

for ns in "${namespaces[@]}"; do
  echo "👉 Processing namespace: $ns"

  kubectl get namespace "$ns" -o json > "$ns.json"

  # Remove finalizers using jq
  jq 'del(.spec.finalizers)' "$ns.json" > "$ns-final.json"

  # Apply the finalized version
  kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f "$ns-final.json"

  # Cleanup
  rm "$ns.json" "$ns-final.json"

  echo "✅ Namespace $ns finalized and deleted"
done

echo "🎉 All specified namespaces processed."
