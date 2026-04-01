# Image Optimization

## General Rules
- Use modern formats: WebP or AVIF for photos, SVG for icons/logos
- Compress images before adding to the project
- Set explicit width and height to prevent layout shift (CLS)
- Lazy load images below the fold
- Only prioritize above-the-fold images (hero, logo) — max 1-2 per page

## Responsive Images
Serve the right size for the user's screen:
- Provide multiple sizes via srcset or framework image components
- Use `sizes` attribute to tell the browser which size to pick
- Don't serve a 2000px image for a 300px thumbnail

## Framework Image Components
Most frameworks optimize images automatically:
- **Next.js**: `next/image` — auto format conversion, lazy loading, responsive
- **Nuxt**: `nuxt-image` — same benefits for Vue ecosystem
- **SvelteKit**: `@sveltejs/enhanced-img` or svelte-image
- **Rails**: Active Storage variants with libvips
- **Django**: django-imagekit or sorl-thumbnail
- **Laravel**: Intervention Image

Use the framework's component instead of raw `<img>` tags.

## Performance Impact
- Hero image loads with `priority` / `eager` — it's the LCP element
- All other images load lazily (most frameworks do this by default)
- Provide width/height or aspect-ratio to reserve space (prevents CLS)
- Use CDN for image delivery (Cloudflare Images, imgix, Cloudinary)

## Icons and Logos
- Use SVG for icons and logos (infinitely scalable, tiny file size)
- Inline small SVGs directly in markup for fewer HTTP requests
- Use an icon library (Lucide, Heroicons, Phosphor) instead of custom images for common icons

## Common Mistakes
- Using raw `<img>` when a framework image component exists
- Setting priority/eager on every image (defeats the purpose)
- Missing alt text (accessibility violation)
- Not setting dimensions (causes layout shift)
- Serving huge source images for small display areas
