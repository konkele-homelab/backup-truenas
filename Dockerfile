FROM registry.lab.konkel.us/backup-base:latest

# TrueNAS Backup Script
ARG SCRIPT_FILE=backup-truenas.sh

# Install Application Specific Backup Script
ENV APP_BACKUP=/config/${SCRIPT_FILE}
COPY ${SCRIPT_FILE} ${APP_BACKUP}
RUN chmod +x ${APP_BACKUP}
