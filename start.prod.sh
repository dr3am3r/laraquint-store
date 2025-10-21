#!/bin/sh
set -e

echo "🚀 Starting Medusa in production mode..."

# Run migrations
echo "📊 Running database migrations..."
npx medusa db:migrate

# Always build admin on startup for server mode (volumes override Docker build)
if [ "$MEDUSA_WORKER_MODE" = "server" ] || [ -z "$MEDUSA_WORKER_MODE" ]; then
    echo "🔨 Building admin dashboard..."
    npx medusa build
    echo "✅ Admin build completed!"
fi

# Check worker mode and start appropriately
if [ "$MEDUSA_WORKER_MODE" = "worker" ]; then
    echo "👷 Starting Medusa worker (background jobs only)..."
    npx medusa start
elif [ "$MEDUSA_WORKER_MODE" = "server" ]; then
    echo "🌐 Starting Medusa server (API + Admin)..."
    npx medusa start
else
    echo "⚠️  MEDUSA_WORKER_MODE not set, starting in shared mode..."
    npx medusa start
fi
