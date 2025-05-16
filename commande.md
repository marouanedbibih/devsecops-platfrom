kubectl create secret generic sonarqube-monitoring-secret \
  --from-literal=passcode=passcode \
  -n sonarqube