# Rollback Strategy

## Principle
Every deploy must be reversible. If production breaks, you need to recover in minutes, not hours.

## Instant Rollback (Platform-Level)
Most deployment platforms support instant rollback to the previous deploy:
- **Vercel**: Dashboard → Deployments → click previous deploy → "Promote to Production"
- **Railway**: Dashboard → Deployments → Rollback button
- **Heroku**: `heroku releases:rollback`
- **AWS**: CloudFormation rollback, ECS task revision rollback
- **Fly.io**: `fly releases rollback`

## Database Rollback
Code rollback is instant. Database rollback is NOT — migrations go forward.

**Before every migration:**
- Write the UP migration (apply change)
- Write the DOWN migration (reverse the change)
- Test the DOWN migration works in development
- Never delete columns/tables in the same deploy as the code change — do it in a LATER deploy after the code no longer references them

**Two-phase migration pattern:**
1. Deploy 1: Add new column (nullable), deploy code that writes to both old and new
2. Deploy 2: Backfill data, switch reads to new column
3. Deploy 3: Remove old column (only after code no longer uses it)

## When Things Go Wrong
1. **App crashes on deploy** → instant rollback via platform
2. **Data looks wrong** → run DOWN migration, then rollback code
3. **Performance degraded** → rollback code, investigate in development
4. **Security issue found** → rollback IMMEDIATELY, then investigate

## Checklist
- [ ] Every migration has a reversible DOWN migration
- [ ] Deployment platform supports one-click rollback
- [ ] Team knows how to rollback (documented, not just known)
- [ ] Database changes are backward-compatible (two-phase pattern)
- [ ] Rollback tested in staging before production deploy
