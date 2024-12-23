#!/usr/bin/env bash
#
# container_security_check.sh
#
# SYNOPSIS
#   Performs advanced checks on Docker or Kubernetes for security misconfigurations.
#
# DESCRIPTION
#   - Checks Docker daemon config for insecure registries or disabled seccomp.
#   - If KUBECONFIG is set, checks for pods running privileged or with host namespaces.
#   - Logs findings to /var/log/container_security_check.log
#

LOGFILE="/var/log/container_security_check.log"

echo "===== Starting Container Security Check at $(date) =====" | tee -a "$LOGFILE"

# 1. Check if Docker is installed and running
if command -v docker >/dev/null 2>&1; then
  dockerInfo=$(docker info 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "WARNING: Docker is installed but cannot run 'docker info' (permissions?)." | tee -a "$LOGFILE"
  else
    echo "$dockerInfo" | grep -i 'Insecure Registries' -A5 | tee -a "$LOGFILE"
    # Check if seccomp is used
    echo "Checking if default seccomp profile is applied by default..."
    # This might require analyzing /etc/docker/daemon.json or 'docker info' deeper.
    if ! echo "$dockerInfo" | grep -qi 'seccomp'; then
      echo "WARNING: Seccomp not detected. Docker might not be using the default seccomp profile." | tee -a "$LOGFILE"
    fi
  fi
else
  echo "Docker not found. Skipping Docker checks." | tee -a "$LOGFILE"
fi

# 2. Kubernetes checks if kubectl is installed and KUBECONFIG is set
if command -v kubectl >/dev/null 2>&1; then
  if [ -z "$KUBECONFIG" ]; then
    echo "WARNING: KUBECONFIG not set. Skipping K8s checks." | tee -a "$LOGFILE"
  else
    echo "Fetching pods that might be privileged or using host namespaces..." | tee -a "$LOGFILE"
    kubectl get pods --all-namespaces -o json | jq -r '
      .items[] 
      | select(.spec.containers[]?.securityContext?.privileged == true 
               or .spec.hostPID == true 
               or .spec.hostNetwork == true) 
      | "WARNING: Privileged/hostPod => \(.metadata.namespace)/\(.metadata.name)"' | tee -a "$LOGFILE"
  fi
else
  echo "kubectl not found. Skipping K8s checks." | tee -a "$LOGFILE"
fi

echo "===== Container Security Check Completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
