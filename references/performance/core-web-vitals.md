# Core Web Vitals & Performance

## Target Metrics (Web Applications)
- **LCP** (Largest Contentful Paint): < 2.5 seconds
- **INP** (Interaction to Next Paint): < 200 milliseconds
- **CLS** (Cumulative Layout Shift): < 0.1

For non-web applications (APIs, CLI tools, desktop apps), focus on response time and throughput instead.

## LCP Optimization
- Prioritize above-the-fold content loading
- Preload critical fonts and images
- Avoid client-side data fetching for initial page content — render on server
- Minimize redirect chains
- Use lazy loading only for below-the-fold content

## INP Optimization
- Debounce expensive event handlers (search, resize, scroll)
- Move heavy computation off the main thread (web workers, background tasks)
- Use optimistic UI updates — show the result immediately, sync later
- Use passive event listeners for scroll/touch handlers

## CLS Prevention
- Always set explicit dimensions on images and media
- Reserve space for dynamic content (ads, embeds, lazy components)
- Never inject content above existing content after page load
- Use CSS aspect-ratio for responsive media containers

## API/Server Performance
- Set response time budgets: p50 < 100ms, p99 < 500ms for most endpoints
- Use connection pooling for database connections
- Implement request timeouts (10-30 seconds, not infinite)
- Profile hot paths — optimize the 20% of code that handles 80% of traffic
- Use async/non-blocking I/O for I/O-bound operations

## Bundle Size (Web Applications)
- Never import from barrel files (index.ts/index.js) — import specific modules
- Lazy load heavy components not needed on initial render
- Lazy load third-party scripts (analytics, chat widgets)
- Analyze bundle with: webpack-bundle-analyzer, @next/bundle-analyzer, rollup-plugin-visualizer
- Tree shake unused code — use ES modules (import/export), not CommonJS (require)

## Monitoring
- Measure Core Web Vitals in production (real user metrics, not just lab)
- Set up alerts for p99 latency spikes
- Track error rates per endpoint
- Use APM tools (Datadog, New Relic, Sentry Performance) for production visibility
