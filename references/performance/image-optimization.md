# Image Optimization

## Next.js Image Component
Always use `next/image` instead of `<img>`:
```tsx
import Image from 'next/image'

<Image
  src="/hero.jpg"
  alt="Description of the image"
  width={1200}
  height={600}
  priority  // Only for above-the-fold images
/>
```

## Rules
- `priority` prop ONLY on above-the-fold images (hero, logo). Max 1-2 per page.
- All other images lazy-load by default (next/image does this automatically)
- Always provide `width` and `height` to prevent layout shift (CLS)
- Use `sizes` prop for responsive images to serve correct size
```tsx
<Image
  src="/photo.jpg"
  alt="..."
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, 50vw"
/>
```

## Format
- Let Next.js handle format conversion (serves WebP/AVIF automatically)
- For external images, configure `remotePatterns` in next.config.ts
- Compress source images before adding to project (use squoosh.app or similar)
- SVGs for icons and logos, raster for photos

## Common Mistakes
- Using `<img>` instead of `next/image` — loses optimization, lazy loading, format conversion
- Setting `priority` on every image — defeats the purpose, slows page load
- Missing `alt` text — accessibility violation
- Not setting dimensions — causes layout shift (CLS penalty)
- Loading huge source images for small display sizes
