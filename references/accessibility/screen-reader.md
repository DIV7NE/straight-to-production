# Screen Reader Compatibility

## Semantic HTML First
Use the right element — ARIA is a last resort, not a first choice.

| Need | Use | NOT |
|------|-----|-----|
| Navigation | `<nav>` | `<div role="navigation">` |
| Main content | `<main>` | `<div role="main">` |
| Button | `<button>` | `<div onClick>` |
| Link | `<a href>` | `<span onClick>` |
| List | `<ul>/<ol>` | `<div>` with styled items |
| Heading | `<h1>-<h6>` | `<div className="text-2xl">` |

## ARIA When Needed

### Labels for icon-only buttons
```tsx
<button aria-label="Close menu">
  <XIcon />
</button>
```

### Live regions for dynamic content
```tsx
<div aria-live="polite" aria-atomic="true">
  {statusMessage}
</div>
```
Use `aria-live="polite"` for non-urgent updates, `"assertive"` for critical alerts.

### Form error association
```tsx
<label htmlFor="email">Email</label>
<input id="email" aria-describedby="email-error" aria-invalid={!!error} />
{error && <p id="email-error" role="alert">{error}</p>}
```

## Images
- Informative images: descriptive alt text (`alt="Graph showing 40% growth in Q3"`)
- Decorative images: empty alt (`alt=""`)
- Complex images: alt text + longer description via `aria-describedby`
- Never use alt text like "image", "photo", "icon" — describe what the image conveys

## Testing
- Mac: Cmd+F5 to toggle VoiceOver, then navigate with VoiceOver keys
- Check: are headings announced in order? Are buttons labeled? Are form fields described?
