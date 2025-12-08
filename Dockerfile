FROM registry.lab.konkel.us/backup-base:latest

# TrueNAS Backup Script
ARG APP_BACKUP=backup-truenas.sh

# Install Application Specific Backup Script
ENV APP_BACKUP=${APP_BACKUP}
COPY ${APP_BACKUP} /config/${APP_BACKUP}
RUN chmod +x /config/${APP_BACKUP}
