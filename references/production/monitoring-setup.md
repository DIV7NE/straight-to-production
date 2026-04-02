# Post-Launch Monitoring

## Principle
You should know your app is broken BEFORE your users tell you. Monitoring is how.

## Three Things to Monitor

### 1. Errors (something broke)
**Tool**: Sentry (recommended), Datadog, Bugsnag

Setup:
- Install the SDK for your framework
- Configure in your app's entry point
- Errors are captured automatically with: stack trace, user context, request data
- Set up alerts: email/Slack when error rate spikes

What it catches:
- Unhandled exceptions in production
- API route failures
- Client-side crashes
- Which user was affected and what they were doing

### 2. Uptime (is the app reachable?)
**Tool**: Better Uptime, UptimeRobot (free tier), Vercel Analytics

Setup:
- Point the monitor at your health check endpoint: `GET /api/health`
- Check every 1-5 minutes
- Alert if down for > 1 minute

What it catches:
- Server is down
- DNS issues
- SSL certificate expiration
- Deployment broke the app

### 3. Performance (is the app fast?)
**Tool**: Vercel Analytics (built-in), PostHog, Google Analytics

Monitor:
- Page load times (LCP target: < 2.5s)
- API response times (p99 target: < 500ms)
- Core Web Vitals (LCP, INP, CLS)

What it catches:
- Slow queries (needs indexing or optimization)
- Heavy pages (needs code splitting)
- Performance regression from new deploys

## Alerts That Matter (don't alert on noise)

| Alert | Threshold | Channel |
|-------|-----------|---------|
| Error rate spike | > 10 errors/minute (adjust for traffic) | Slack + email |
| App down | > 1 minute | Slack + email + SMS |
| Slow API | p99 > 2 seconds | Email (daily digest) |
| High error rate | > 5% of requests failing | Slack |
| SSL expiring | < 14 days | Email |

## Health Check Endpoint

Every app should have `GET /api/health` (or equivalent) that returns:
```json
{
  "status": "ok",
  "database": "connected",
  "version": "0.2.3",
  "timestamp": "2026-04-02T12:00:00Z"
}
```

This is what uptime monitors check. It should verify:
- The app is running
- The database is reachable
- The current version (for deploy verification)

## Checklist
- [ ] Error tracking service installed and configured (Sentry recommended)
- [ ] Uptime monitor pointing at /api/health
- [ ] Alerts configured (error rate, downtime)
- [ ] Health check endpoint returns database status
- [ ] Performance monitoring capturing Core Web Vitals
- [ ] First alert test sent (verify alerts actually reach you)
