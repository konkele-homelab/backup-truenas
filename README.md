# TrueNAS Backup Docker Container

This repository contains a minimal Docker image to automate TrueNAS configuration backups using a shell script. The container supports environment-based configuration, UID/GID assignment, and Swarm secrets for credentials.

---

## Features

- Backup multiple TrueNAS hosts using API keys
- Export configuration with optional secret seed (.tar or .db)
- Swarm secret support for storing credentials.
- Configurable backup directory and retention period
- Automatic pruning of old backups
- Runs as non-root user with configurable UID/GID
- Lightweight Alpine base image.

---

## Environment Variables

| Variable          | Default                       | Description |
|-------------------|-------------------------------|-------------|
| SERVERS_FILE      | `/config/servers`      | Path to file or secret containing TrueNAS credentials (`FQDN:API_KEY`)    |
| PROTO             | `https`                | Protocol to use when contacting TrueNAS (http/https) |
| SECRETSEED        | `true`                 | Include secret seed in backup (tar if true, db if false) |
| DEBUG             | `false`                | If `true`, keep container running forever for debug purposes |
| BACKUP_DEST       | `/backup`              | Directory where backup output is stored |
| LOG_FILE          | `/var/log/backup.log`  | Persistent log file |
| EMAIL_ON_SUCCESS  | `false`                | Enable sending email when backup succeeds (`true`/`false`) |
| EMAIL_ON_FAILURE  | `false`                | Enable sending email when backup fails (`true`/`false`) |
| EMAIL_TO          | `admin@example.com`    | Recipient of status notifications |
| EMAIL_FROM        | `backup@example.com`   | Sender of status notifications |
| APP_BACKUP        | `/default.sh`          | Path to backup script executed by the container |
| KEEP_DAYS         | `30`                   | Number of days to retain backups |
| USER_UID          | `3000`                 | UID of backup user |
| USER_GID          | `3000`                 | GID of backup user |
| DRY_RUN           | `false`                | If `true`, backup logic logs actions but does not backup or prune anything |
| TZ                | `UTC`                  | Timezone used for timestamps |

---

## Servers File Format

The servers file should contain lines in the following format:
```
hostname_or_ip:API_KEY
```
Example:
```
truenas.example.com:abc123secretkey
192.168.1.50:def456apikey
```

---

## Docker Compose Example (Swarm)

```yaml
version: "3.9"

services:
  backup-truenas:
    image: your-dockerhub-username/backup-truenas:latest
    environment:
      BACKUP_DEST: /backup
      SERVERS_FILE: /run/secrets/backup-truenas
      SECRETSEED: true
    volumes:
      - /backup:/backup
    secrets:
      - backup-truenas
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: none

secrets:
  backup-truenas:
    external: true
```

---

### Usage

1. Create the Swarm secret:
```bash
docker secret create backup-truenas ./servers
```
2. Deploy the stack:
```bash
docker stack deploy -c docker-compose.yml backup-truenas_stack
```

---

## Local Testing

For testing without Swarm, you can mount the servers file and run the container directly:
```bash
docker run -it --rm \
  -v /backup:/backup \
  -v ./servers:/config/servers \
  -e SCRIPT_NAME=backup-truenas.sh \
  your-dockerhub-username/backup-truenas:latest
```

---

## Logging

- Each backup logs start time, end time, and the backup file path
- Pruned backups are also logged
- Errors are logged to `stderr`

---

## Notes

- Ensure your API keys have proper permissions to retrieve configurations.
- The container defaults to `/backup` as the backup directory.
- Modify `KEEP_DAYS` to retain backups for a longer period if needed.
