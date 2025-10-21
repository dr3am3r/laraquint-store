#!/bin/bash
set -e

# Backup script for Medusa production database
# Usage: ./backup.sh

BACKUP_DIR="$HOME/laraquint-store/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/medusa_backup_$TIMESTAMP.sql"
CONTAINER_NAME="medusa_postgres"

# Load environment variables
if [ -f "$HOME/laraquint-store/.env.production" ]; then
    export $(cat $HOME/laraquint-store/.env.production | grep -v '^#' | xargs)
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "🔄 Starting database backup..."
echo "📁 Backup location: $BACKUP_FILE"

# Create backup
docker exec $CONTAINER_NAME pg_dump \
    -U ${POSTGRES_USER:-medusa} \
    -d ${POSTGRES_DB:-medusa-store} \
    > "$BACKUP_FILE"

# Compress the backup
gzip "$BACKUP_FILE"
echo "✅ Backup completed: ${BACKUP_FILE}.gz"

# Keep only last 7 days of backups
echo "🧹 Cleaning old backups (keeping last 7 days)..."
find "$BACKUP_DIR" -name "medusa_backup_*.sql.gz" -mtime +7 -delete

# Show backup size
BACKUP_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
echo "📊 Backup size: $BACKUP_SIZE"

# List recent backups
echo ""
echo "📋 Recent backups:"
ls -lh "$BACKUP_DIR" | tail -n 5

echo ""
echo "✨ Backup complete!"
