# Query & Data Fetching Optimization

## The N+1 Problem
The #1 performance killer across all stacks. Loading a list of items, then making a separate query for each item's related data.

```
WRONG (N+1 — 101 queries for 100 items):
  items = get_all_items()          # 1 query
  for item in items:
    item.author = get_author(item.author_id)  # 100 queries

CORRECT (2 queries for 100 items):
  items = get_all_items()          # 1 query
  authors = get_authors(item.author_ids)  # 1 query with IN clause
  # join in application code
```

Detection: if you see a database call inside a loop, it's likely N+1.

## Parallel Queries
When fetching multiple independent pieces of data, fetch them in parallel:

```
WRONG (sequential — total time = sum of all queries):
  user = await get_user(id)       # 500ms
  posts = await get_posts(id)     # 300ms  
  stats = await get_stats(id)     # 200ms
  # Total: 1000ms

CORRECT (parallel — total time = slowest query):
  user, posts, stats = await all(
    get_user(id),      # 500ms
    get_posts(id),     # 300ms
    get_stats(id),     # 200ms
  )
  # Total: 500ms
```

Language-specific parallel patterns:
- **JavaScript**: `Promise.all([...])`
- **Python**: `asyncio.gather(...)` or `concurrent.futures`
- **Rust**: `tokio::join!(...)`
- **Go**: goroutines + channels or errgroup
- **C#**: `Task.WhenAll(...)`
- **Java**: `CompletableFuture.allOf(...)`

## Indexing Strategy
- Add database indexes on columns used in WHERE, JOIN, and ORDER BY clauses
- Composite indexes for multi-column queries (order matters — most selective first)
- Don't over-index: each index slows writes. Only index what queries actually use.
- Monitor slow queries in production and add indexes based on real data

## Caching Layers
From closest to user to furthest:
1. **Browser cache** — static assets, API responses with cache headers
2. **CDN cache** — static pages, images, public API responses
3. **Application cache** — computed results, database query results (Redis, Memcached)
4. **Database cache** — query plan cache, buffer pool (usually automatic)

Cache invalidation rules:
- Set TTL (time-to-live) appropriate to data staleness tolerance
- Invalidate on write (when data changes, clear the cache)
- Use cache tags for bulk invalidation
- Never cache sensitive/personalized data in shared caches

## Pagination
- NEVER load unbounded result sets (no `SELECT *` without LIMIT)
- Use cursor-based pagination for real-time data (more reliable than offset)
- Use offset pagination for static/sorted data (simpler to implement)
- Default page size: 20-50 items. Max: 100-200.
- Return total count and pagination metadata in responses
