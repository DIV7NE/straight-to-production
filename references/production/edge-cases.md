# Edge Cases for Production

## Offline/Network Handling
- Detect offline state and show a banner: "You're offline. Changes will sync when reconnected."
- Queue mutations when offline if using optimistic updates
- Handle `fetch` failures gracefully (don't assume network always works)

## Slow Connections
- Set reasonable timeouts on fetch calls (10-30 seconds, not infinite)
- Show progress indicators for file uploads
- Use `AbortController` for cancellable requests
```typescript
const controller = new AbortController()
const timeout = setTimeout(() => controller.abort(), 10000)
const response = await fetch(url, { signal: controller.signal })
clearTimeout(timeout)
```

## Concurrent Edits
- If multiple users can edit the same resource, handle conflicts
- Simple: last-write-wins with timestamp check
- Better: optimistic locking with version field
- Show "This item was modified by someone else. Refresh to see changes."

## Session Expiry
- Handle 401 responses globally (redirect to login)
- Show "Your session has expired. Please sign in again." (not a blank error)
- Preserve the URL they were trying to access for post-login redirect

## Timezone Handling
- Store all dates as UTC in the database
- Convert to user's timezone only for display
- Use `Intl.DateTimeFormat` for locale-aware formatting
- Never use `new Date().toLocaleDateString()` without explicit locale

## Large Data Sets
- Paginate lists (don't load 10,000 items at once)
- Use cursor-based pagination for real-time data
- Virtual scrolling for long lists (react-window or @tanstack/virtual)
- Implement search server-side, not client-side filtering

## File Uploads
- Validate file type and size client-side (for UX) AND server-side (for security)
- Show upload progress with percentage
- Handle upload failures with retry option
- Set maximum file sizes appropriate to your use case
- Scan uploaded files for malware if user-facing

## Form Handling
- Preserve form state on validation errors (don't clear the form)
- Handle double-submit (disable button during submission)
- Confirm before navigating away from unsaved changes
- Handle paste events for multi-field forms (e.g., address auto-fill)
