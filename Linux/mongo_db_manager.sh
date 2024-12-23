#!/usr/bin/env bash
#
# mongo_db_manager.sh
#
# SYNOPSIS
#   Creates or rebuilds a MongoDB database on a Linux host. Optionally runs .js scripts.
#

MONGO_HOST="$1"
DB_NAME="$2"
REBUILD="$3"  # "true" or "false"
SCRIPT_FOLDER="$4"  # optional path to .js/.mongo scripts
LOGFILE="/var/log/mongo_db_manager.log"

echo "===== Starting mongo_db_manager.sh at $(date) =====" | tee -a "$LOGFILE"

if [ -z "$MONGO_HOST" ] || [ -z "$DB_NAME" ]; then
  echo "Usage: $0 <MONGO_HOST> <DB_NAME> [REBUILD=true|false] [SCRIPT_FOLDER]" | tee -a "$LOGFILE"
  exit 1
fi

# 1. Drop DB if REBUILD=true
if [ "$REBUILD" = "true" ]; then
  echo "Dropping database $DB_NAME if it exists..." | tee -a "$LOGFILE"
  mongosh --host "$MONGO_HOST" --eval "db.getSiblingDB('$DB_NAME').dropDatabase()" 2>>"$LOGFILE"
fi

# 2. Run scripts or create default collection
if [ -n "$SCRIPT_FOLDER" ] && [ -d "$SCRIPT_FOLDER" ]; then
  echo "Executing scripts in $SCRIPT_FOLDER for $DB_NAME..." | tee -a "$LOGFILE"
  for file in "$SCRIPT_FOLDER"/*.js "$SCRIPT_FOLDER"/*.mongo; do
    if [ -f "$file" ]; then
      echo "Running $file..." | tee -a "$LOGFILE"
      mongosh --host "$MONGO_HOST" "$DB_NAME" "$file" 2>>"$LOGFILE"
    fi
  done
else
  echo "No script folder provided. Creating a default collection in $DB_NAME." | tee -a "$LOGFILE"
  mongosh --host "$MONGO_HOST" "$DB_NAME" --eval "db.createCollection('defaultCollection')" 2>>"$LOGFILE"
fi

echo "===== mongo_db_manager.sh completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
