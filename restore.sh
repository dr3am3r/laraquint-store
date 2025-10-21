#!/bin/bash
set -e

# Restore script for Medusa production database
# Usage: ./restore.sh <backup_file.sql.gz>

if [ -z "$1" ]; then
    echo "❌ Error: No backup file specified"
    echo "Usage: ./restore.sh <backup_file.sql.gz>"
    echo ""
    echo "Available backups:"
    ls -lh ~/laraquint-store/backups/*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"
CONTAINER_NAME="medusa_postgres"

# Load environment variables
if [ -f "$HOME/laraquint-store/.env.production" ]; then
    export $(cat $HOME/laraquint-store/.env.production | grep -v '^#' | xargs)
fi

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "⚠️  WARNING: This will restore the database from backup!"
echo "📁 Backup file: $BACKUP_FILE"
echo "🗄️  Database: ${POSTGRES_DB:-medusa-store}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "❌ Restore cancelled"
    exit 1
fi

echo "🔄 Starting database restore..."

# Decompress if needed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "📦 Decompressing backup..."
    gunzip -c "$BACKUP_FILE" | docker exec -i $CONTAINER_NAME psql \
        -U ${POSTGRES_USER:-medusa} \
        -d ${POSTGRES_DB:-medusa-store}
else
    cat "$BACKUP_FILE" | docker exec -i $CONTAINER_NAME psql \
        -U ${POSTGRES_USER:-medusa} \
        -d ${POSTGRES_DB:-medusa-store}
fi

echo "✅ Database restored successfully!"
echo "🔄 Restarting Medusa services..."

cd ~/laraquint-store
docker compose -f docker-compose.prod.yml restart medusa-server medusa-worker

echo "✨ Restore complete!"
