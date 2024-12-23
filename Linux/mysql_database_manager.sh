#!/usr/bin/env bash
#
# mysql_database_manager.sh
#
# SYNOPSIS
#   Creates or rebuilds a MySQL/MariaDB database, optionally loads .sql files.
#

DB_NAME="$1"
REBUILD="$2"  # "true" or "false"
SQL_FOLDER="$3"
DB_USER="UserName"
DB_PASS="***Password***"
LOGFILE="/var/log/mysql_database_manager.log"

echo "===== Starting MySQL Database Manager at $(date) =====" | tee -a "$LOGFILE"

if [ -z "$DB_NAME" ]; then
  echo "Usage: $0 <DB_NAME> [REBUILD=true|false] [SQL_FOLDER]" | tee -a "$LOGFILE"
  exit 1
fi

# 1. Check if DB exists
DB_EXISTS=$(mysql -u"$DB_USER" -p"$DB_PASS" -sse "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$DB_NAME';")
if [ "$DB_EXISTS" == "$DB_NAME" ]; then
  if [ "$REBUILD" == "true" ]; then
    echo "Dropping and recreating DB $DB_NAME..." | tee -a "$LOGFILE"
    mysql -u"$DB_USER" -p"$DB_PASS" -e "DROP DATABASE \`$DB_NAME\`;" 2>>"$LOGFILE"
    mysql -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE \`$DB_NAME\`;" 2>>"$LOGFILE"
  else
    echo "Database $DB_NAME already exists. Skipping creation..." | tee -a "$LOGFILE"
  fi
else
  echo "Creating new DB $DB_NAME..." | tee -a "$LOGFILE"
  mysql -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE \`$DB_NAME\`;" 2>>"$LOGFILE"
fi

# 2. Load SQL scripts
if [ -n "$SQL_FOLDER" ] && [ -d "$SQL_FOLDER" ]; then
  echo "Loading SQL files from $SQL_FOLDER into $DB_NAME" | tee -a "$LOGFILE"
  for file in "$SQL_FOLDER"/*.sql; do
    if [ -f "$file" ]; then
      echo "Executing $file..." | tee -a "$LOGFILE"
      mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$file" 2>>"$LOGFILE"
    fi
  done
fi

echo "===== MySQL Database Manager completed at $(date) =====" | tee -a "$LOGFILE"
exit 0
