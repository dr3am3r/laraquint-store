#!/bin/sh
set -e

echo "🚀 Starting Medusa in production mode..."

# Run migrations
echo "📊 Running database migrations..."
npx medusa db:migrate

# Rebuild admin if .medusa doesn't exist (only for server mode)
if [ "$MEDUSA_WORKER_MODE" = "server" ] || [ -z "$MEDUSA_WORKER_MODE" ]; then
    if [ ! -f "/server/.medusa/server/public/index.html" ]; then
        echo "🔨 Admin build not found, rebuilding..."
        npx medusa build

        # Wait and verify the build completed successfully
        echo "⏳ Verifying admin build completion..."
        if [ ! -f "/server/.medusa/server/public/index.html" ]; then
            echo "❌ ERROR: Admin build failed - index.html not found!"
            echo "Build directory contents:"
            ls -la /server/.medusa/server/public/ || echo "Directory doesn't exist"
            exit 1
        fi
        echo "✅ Admin build completed successfully!"
    else
        echo "✅ Admin build found, skipping rebuild"
    fi
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
