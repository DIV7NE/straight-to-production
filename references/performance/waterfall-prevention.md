# Waterfall Prevention

## The Problem
Sequential async calls are the #1 performance killer in Next.js apps. Each `await` blocks the next, creating a "waterfall" where total time = sum of all calls.

## The Pattern: Parallelize Independent Fetches

### WRONG (waterfall — 3 seconds total)
```typescript
const user = await getUser(id)        // 1s
const posts = await getPosts(id)      // 1s
const stats = await getStats(id)      // 1s
// Total: 3 seconds
```

### CORRECT (parallel — 1 second total)
```typescript
const [user, posts, stats] = await Promise.all([
  getUser(id),
  getPosts(id),
  getStats(id),
])
// Total: 1 second (slowest call)
```

## Next.js Server Component Pattern
Use component composition to parallelize at the component level:

### WRONG (sequential in parent)
```tsx
export default async function Dashboard() {
  const user = await getUser()
  const posts = await getPosts()
  const stats = await getStats()
  return <Page user={user} posts={posts} stats={stats} />
}
```

### CORRECT (parallel via Suspense)
```tsx
export default function Dashboard() {
  return (
    <>
      <Suspense fallback={<UserSkeleton />}>
        <UserPanel />
      </Suspense>
      <Suspense fallback={<PostsSkeleton />}>
        <PostsList />
      </Suspense>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel />
      </Suspense>
    </>
  )
}
```
Each component fetches its own data. They load in parallel and stream in as ready.

## Detection
Run: `grep -rn "await.*\n.*await" --include="*.ts" --include="*.tsx" src/`
Look for consecutive awaits in the same function that don't depend on each other.

## API Route Waterfalls
Same pattern applies in API routes. If you need data from multiple sources:
```typescript
const [dbResult, externalApi, cache] = await Promise.all([
  db.query(...),
  fetch('https://api.example.com/...'),
  redis.get('key'),
])
```
