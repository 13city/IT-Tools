#!/usr/bin/env bash
#
# pg_database_manager.sh
#
# SYNOPSIS
#   Creates, drops, or rebuilds a PostgreSQL database. Optionally loads SQL files.
#

DB_NAME="$1"
REBUILD="$2"       # "true" or "false"
SQL_FOLDER="$3"    # optional path to .sql files
PGUSER="postgres"  # user with sufficient privileges
PGHOST="localhost"
LOGFILE="/var/log/pg_database_manager.log"

echo "===== Starting PostgreSQL Database Manager at $(date) =====" | tee -a "$LOGFILE"

if [ -z "$DB_NAME" ]; then
  echo "Usage: $0 <DB_NAME> [REBUILD=true|false] [SQL_FOLDER]" | tee -a "$LOGFILE"
  exit 1
fi

# 1. Check if DB exists
DB_EXISTS=$(psql -U "$PGUSER" -h "$PGHOST" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';")
if [ "$DB_EXISTS" = "1" ]; then
  if [ "$REBUILD" = "true" ]; then
    echo "Dropping and recreating database $DB_NAME..." | tee -a "$LOGFILE"
    psql -U "$PGUSER" -h "$PGHOST" -c "DROP DATABASE \"$DB_NAME\";" 2>>"$LOGFILE"
    psql -U "$PGUSER" -h "$PGHOST" -c "CREATE DATABASE \"$DB_NAME\";" 2>>"$LOGFILE"
  else
    echo "Database $DB_NAME already exists. Skipping creation..." | tee -a "$LOGFILE"
  fi
else
  echo "Creating new database $DB_NAME..." | tee -a "$LOGFILE"
  psql -U "$PGUSER" -h "$PGHOST" -c "CREATE DATABASE \"$DB_NAME\";" 2>>"$LOGFILE"
fi

# 2. Load .sql files if provided
if [ -n "$SQL_FOLDER" ] && [ -d "$SQL_FOLDER" ]; then
  echo "Loading SQL files from $SQL_FOLDER into $DB_NAME" | tee -a "$LOGFILE"
  for file in "$SQL_FOLDER"/*.sql; do
    echo "Executing $file..." | tee -a "$LOGFILE"
    psql -U "$PGUSER" -h "$PGHOST" -d "$DB_NAME" -f "$file" 2>>"$LOGFILE"
  done
fi

echo "===== PostgreSQL Database Manager completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
