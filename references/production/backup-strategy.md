# Backup & Disaster Recovery

## Principle
If your database disappeared right now, how fast could you recover? The answer should be "minutes."

## Database Backups

### Automated Backups (non-negotiable)
- **Supabase**: Daily automatic backups (Pro plan), point-in-time recovery
- **Railway**: Daily snapshots
- **AWS RDS**: Automated daily snapshots + transaction logs for point-in-time
- **PlanetScale**: Automatic branching serves as backup
- **Self-hosted Postgres**: Set up pg_dump on a cron job

### Backup Schedule
- **Daily**: Full database backup (automated by your provider)
- **Before migrations**: Manual backup before any schema change
- **Before risky operations**: Manual backup before bulk data operations

### Test Your Backups
A backup you've never restored is not a backup. Monthly:
1. Download a backup
2. Restore it to a test environment
3. Verify the data is complete and correct

## File/Asset Backups
- **User uploads** (images, documents): stored in Supabase Storage / S3 / Cloudflare R2
- Cloud storage providers handle replication automatically
- Enable versioning on your storage bucket (recover from accidental deletes)

## Code Backups
- Git IS your code backup (if pushed to remote)
- Ensure `.env` values are documented somewhere secure (not in git)
- Document all third-party API keys and where they're configured

## Recovery Plan
If everything breaks, restore in this order:
1. Database (from latest backup)
2. Deploy latest known-good code (git tag or previous deploy)
3. Verify environment variables are set
4. Run health check endpoint
5. Verify core user workflow works end-to-end

## Checklist
- [ ] Automated daily database backups enabled
- [ ] Backup restoration tested at least once
- [ ] File storage has versioning enabled
- [ ] Environment variables documented securely (not in git)
- [ ] Recovery procedure documented (not just known)
- [ ] Manual backup taken before every migration
