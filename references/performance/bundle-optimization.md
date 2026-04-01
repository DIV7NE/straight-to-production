# Bundle Optimization

## Critical Rule: No Barrel File Imports
```typescript
// NEVER — imports entire components directory, tree shaking fails
import { Button, Card, Input } from '@/components'

// ALWAYS — import from specific module paths
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
```

## Dynamic Imports for Heavy Components
Components not needed on initial render should be lazy loaded:
```typescript
import dynamic from 'next/dynamic'

const Chart = dynamic(() => import('@/components/Chart'), {
  loading: () => <ChartSkeleton />,
})

const Editor = dynamic(() => import('@/components/Editor'), {
  ssr: false, // client-only heavy component
  loading: () => <EditorSkeleton />,
})
```

Good candidates for dynamic import:
- Charts/graphs (recharts, chart.js)
- Rich text editors (tiptap, lexical)
- Code editors (monaco, codemirror)
- Maps (mapbox, google maps)
- PDF viewers
- Modals and dialogs (loaded on interaction)

## Third-Party Script Loading
```tsx
import Script from 'next/script'

// Analytics — load after page is interactive
<Script src="https://..." strategy="afterInteractive" />

// Non-essential — load when browser is idle
<Script src="https://..." strategy="lazyOnload" />
```

## Monitoring Bundle Size
```bash
# Analyze what's in your bundle
npx @next/bundle-analyzer

# Check for large dependencies
npx depcheck
npx cost-of-modules
```

## Tree Shaking Checklist
- Use ES modules (import/export), not CommonJS (require)
- Import specific functions: `import { format } from 'date-fns'` not `import * as dateFns`
- Avoid side-effect imports unless necessary
- Check that tsconfig.json has `"module": "esnext"` or `"nodenext"`
