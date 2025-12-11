#!/bin/sh
set -eu

# ----------------------
# Default variables
# ----------------------
: "${APP_NAME:=TrueNAS}"
: "${BACKUP_DEST:=/backup}"
: "${KEEP_DAYS:=30}"
: "${DRY_RUN:=false}"
: "${TIMESTAMP:=$(date +%Y%m%d-%H%M%S)}"

: "${SERVERS_FILE:=/config/servers}"
: "${PROTO:=https}"
: "${SECRETSEED:=true}"

export APP_NAME
# ----------------------
# TrueNAS Backup
# ----------------------
truenas_backup() {
    host="$1"
    apiKey="$2"

    # Ensure backup destination exists
    mkdir -p "$BACKUP_DEST"
    serverURL="${PROTO}://${host}"

    # Determine output file extension
    if [ "$SECRETSEED" = "true" ]; then
        fileExt="tar"
        json_seed="true"
    else
        fileExt="db"
        json_seed="false"
    fi

    log "Starting backup for ${host}"

    # Retrieve TrueNAS version for filename tagging
    version=$(curl -sk -X GET \
        -H "Authorization: Bearer ${apiKey}" \
        -H "accept: */*" \
        "${serverURL}/api/v2.0/system/version" \
        | tr -d '"' \
        | awk -F '-' '{print $NF}')

    if [ -z "$version" ]; then
        log_error "${host}: Unable to retrieve system version"
        return 1
    fi

    # Build backup filename
    backup="${BACKUP_DEST}/${host}-${version}-${TIMESTAMP}.${fileExt}"

    # Dry run
    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would perform backup for ${host}, saving to ${backup}"
        return 0
    fi

    # Request configuration backup
    if ! curl -sk -X POST \
        -H "Authorization: Bearer ${apiKey}" \
        -H "accept: */*" \
        -H "Content-Type: application/json" \
        -d "{\"secretseed\": ${json_seed}}" \
        "${serverURL}/api/v2.0/config/save" \
        -o "$backup"; then
        log_error "${host}: Backup failed (API error)"
        rm -f "$backup"
        return 1
    fi

    # Validate output file
    if [ ! -s "$backup" ]; then
        log_error "${host}: Backup file is missing or empty"
        rm -f "$backup"
        return 1
    fi

    # Secure file
    chmod 600 "$backup"

    log "Backup saved: ${backup}"
}

# ----------------------
# Backup Execution
# ----------------------
if [ ! -f "$SERVERS_FILE" ]; then
    log_error "Servers file not found: ${SERVERS_FILE}"
    exit 1
fi

# Read server list line by line
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines
    [ -z "$line" ] && continue

    # Split host and API key using POSIX tools
    host=$(echo "$line" | awk -F: '{print $1}')
    api=$(echo "$line" | awk -F: '{print $2}')

    if [ -z "$host" ] || [ -z "$api" ]; then
        log_error "Invalid entry in servers file: ${line}"
        continue
    fi

    # Run backup
    truenas_backup "$host" "$api"

    # Prune old backups
    prune_by_timestamp "${host}-*" "$KEEP_DAYS" "$BACKUP_DEST"

done < "$SERVERS_FILE"

# ----------------------
# Debug: keep container running
# ----------------------
if [ "${DEBUG:-false}" = "true" ]; then
    log "DEBUG mode enabled — container will remain running."
    tail -f /dev/null
fi
