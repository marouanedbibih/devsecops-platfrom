#!/bin/bash
NAMESPACE=$1
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get -n $NAMESPACE -o name 2>/dev/null | while read RESOURCE; do
  kubectl get -n $NAMESPACE $RESOURCE -o json | jq 'if .metadata.finalizers then .metadata.finalizers = [] else . end' | kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/$RESOURCE" -f -  2>/dev/null || true
done
