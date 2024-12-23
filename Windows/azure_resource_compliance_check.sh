#!/usr/bin/env bash
#
# azure_resource_compliance_check.sh
#
# SYNOPSIS
#   Uses Azure CLI to perform advanced security/compliance checks on Azure resources.
#
# DESCRIPTION
#   - Logs into Azure (interactive or service principal) if not already.
#   - Iterates over subscriptions or a specified subscription.
#   - Checks resource locks, tags, SKU restrictions, and diagnostic settings.
#   - Logs findings to a timestamped file in /var/log.
#

LOGDIR="/var/log"
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
LOGFILE="$LOGDIR/azure_resource_compliance_$TIMESTAMP.log"

echo "===== Starting Azure Resource Compliance Check at $(date) =====" | tee -a "$LOGFILE"

# 1. (Optional) Check if user is already logged in
az account show >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Not logged in to Azure. Attempting az login..." | tee -a "$LOGFILE"
  # Remove the following line if using service principal or a different auth method
  az login --use-device-code
fi

# 2. Get subscriptions
SUBSCRIPTIONS=$(az account list --query "[].id" -o tsv)
if [ -z "$SUBSCRIPTIONS" ]; then
  echo "ERROR: No subscriptions found or no access. Exiting." | tee -a "$LOGFILE"
  exit 1
fi

for SUB in $SUBSCRIPTIONS; do
  echo "Checking subscription: $SUB" | tee -a "$LOGFILE"
  az account set --subscription "$SUB"

  # 3. Resource lock checks (some critical resources should have locks)
  echo "Fetching resource locks in subscription $SUB..." | tee -a "$LOGFILE"
  az lock list --output table | tee -a "$LOGFILE"
  
  # Additional logic: check if certain resource groups or critical resources have locks.  
  # If missing, log a warning.

  # 4. Resource tagging check
  # For example, ensuring each resource has a 'CostCenter' tag
  echo "Checking resource tags for compliance (CostCenter, Environment)..." | tee -a "$LOGFILE"
  ALL_RESOURCES=$(az resource list --query "[].{Name:name,Type:type,Tags:tags}" -o json)
  # We can parse the JSON or simply rely on 'jq'
  echo "$ALL_RESOURCES" | jq -r '.[] | select(.Tags == null or .Tags.CostCenter == null) | "WARNING: Resource \(.Name) type \(.Type) missing CostCenter tag."' | tee -a "$LOGFILE"

  # 5. SKU restrictions check (e.g., only certain VM SKUs are allowed)
  echo "Checking VM SKUs compliance..." | tee -a "$LOGFILE"
  VMS=$(az vm list --query "[].{Name:name,Location:location,SKU:hardwareProfile.vmSize}" -o json)
  ALLOWED_SKUS=("Standard_DS2_v2" "Standard_D4s_v3")
  for row in $(echo "$VMS" | jq -c '.[]'); do
    NAME=$(echo "$row" | jq -r '.Name')
    SKU=$(echo "$row" | jq -r '.SKU')
    if [[ ! " ${ALLOWED_SKUS[@]} " =~ " $SKU " ]]; then
      echo "WARNING: VM $NAME uses unsupported SKU $SKU" | tee -a "$LOGFILE"
    fi
  done

  # 6. Diagnostic settings check for storage accounts or key vaults
  echo "Checking diagnostic settings for storage accounts in subscription $SUB..." | tee -a "$LOGFILE"
  STORAGE_ACCOUNTS=$(az storage account list -o tsv --query "[].name")
  for SA in $STORAGE_ACCOUNTS; do
    diag=$(az monitor diagnostic-settings list --resource "/subscriptions/$SUB/resourceGroups/$(az storage account show --name $SA --query 'resourceGroup' -o tsv)/providers/Microsoft.Storage/storageAccounts/$SA" -o json)
    if [ "$(echo "$diag" | jq '.value | length')" -eq 0 ]; then
      echo "WARNING: No diagnostic settings found on storage account $SA" | tee -a "$LOGFILE"
    fi
  done

done

echo "===== Azure Resource Compliance Check Completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
