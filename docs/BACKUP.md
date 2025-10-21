# Database Backup & Restore Guide

## Automated Daily Backups

### Setup Cron Job (Run on Server)

```bash
# SSH into your Hetzner server
ssh deploy@api.laraquint.com

# Make backup script executable
chmod +x ~/laraquint-store/backup.sh

# Open crontab editor
crontab -e

# Add this line to run backup daily at 3 AM UTC
0 3 * * * /home/deploy/laraquint-store/backup.sh >> /home/deploy/laraquint-store/backups/backup.log 2>&1

# Save and exit
```

### Verify Cron Job

```bash
# List cron jobs
crontab -l

# Check backup log
tail -f ~/laraquint-store/backups/backup.log
```

## Manual Backup

```bash
# On server
cd ~/laraquint-store
./backup.sh
```

Backups are stored in: `~/laraquint-store/backups/`

## Restore from Backup

```bash
# List available backups
ls -lh ~/laraquint-store/backups/

# Restore specific backup
cd ~/laraquint-store
./restore.sh ~/laraquint-store/backups/medusa_backup_20251021_030000.sql.gz
```

## Backup Retention

- **Automatic cleanup**: Backups older than 7 days are automatically deleted
- **Manual retention**: Copy important backups to external storage

## Download Backups Locally (Optional)

```bash
# From your local machine
scp deploy@api.laraquint.com:~/laraquint-store/backups/medusa_backup_*.sql.gz ~/Downloads/
```

## Important Notes

- ✅ Database backups are compressed (gzip)
- ✅ Backups include: products, orders, customers, collections, etc.
- ✅ Docker volumes persist data across restarts
- ⚠️  Consider off-site backup storage for production
- ⚠️  Test restore process periodically

## What's Backed Up

**Included:**
- Products and variants
- Collections and categories
- Orders and customers
- Admin users
- Sales channels
- All Medusa data

**Not Included:**
- Product images (stored in Cloudflare R2)
- Admin dashboard build (rebuilt on deploy)
- Application code (in Git repository)

## Restore Process

1. Stop Medusa services (optional, for safety)
2. Run restore script with backup file
3. Services restart automatically
4. Verify data in admin panel

## Emergency Recovery

If server is lost:

1. Create new Hetzner server
2. Install Docker and clone repository
3. Deploy application
4. Restore latest backup
5. Product images already in R2 ✅
