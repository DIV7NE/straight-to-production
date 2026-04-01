# Bundle & Build Optimization

## Code Splitting
Break your application into smaller chunks that load on demand:
- Route-based splitting: each page/route loads only its own code
- Component-based splitting: heavy components load when needed (charts, editors, maps)
- Feature-based splitting: features behind flags load only when active

## Lazy Loading
Components and modules NOT needed on initial render should load on demand:

Good candidates:
- Charts and data visualizations
- Rich text editors
- Code editors
- Maps
- PDF viewers
- Modals and dialogs (load on interaction)
- Admin panels (load when navigating to admin section)

## Tree Shaking
Ensure unused code is eliminated from production builds:
- Use ES modules (import/export), not CommonJS (require/module.exports)
- Import specific functions: `import { format } from 'date-fns'` not `import * as dateFns`
- Avoid side-effect imports unless necessary
- Never import from barrel files (index.ts that re-exports everything)

## Barrel File Anti-Pattern
```
NEVER — imports the entire directory, tree shaking fails:
  import { Button, Card } from '@/components'
  import { formatDate } from '@/utils'

ALWAYS — import from specific module paths:
  import { Button } from '@/components/ui/button'
  import { formatDate } from '@/utils/date'
```

## Third-Party Dependencies
- Audit dependency size before adding (bundlephobia.com for npm)
- Prefer smaller alternatives (date-fns over moment.js, preact over react for simple apps)
- Lazy load analytics, chat widgets, and social scripts
- Check for duplicate dependencies in your bundle

## Build Analysis
Monitor what's in your production build:
- **JavaScript**: webpack-bundle-analyzer, @next/bundle-analyzer, rollup-plugin-visualizer
- **Python**: not applicable (server-side), but watch for large dependency installs
- **Rust**: cargo bloat for binary size analysis
- **Go**: go build with -ldflags for binary size reduction
