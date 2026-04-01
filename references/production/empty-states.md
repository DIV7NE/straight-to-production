# Empty States for Production

## Principle
The first thing a new user sees is an empty state. If it's a blank page, they'll leave. Every list, dashboard, and data view needs a designed empty state.

## Types of Empty States

### Zero Data (new user, nothing created yet)
- Explain what this area is for
- Show a clear call-to-action to create the first item
- Consider showing example content or a quick tutorial
```tsx
function EmptyProjects() {
  return (
    <div className="text-center py-12">
      <h3>No projects yet</h3>
      <p>Create your first project to get started.</p>
      <Button>Create Project</Button>
    </div>
  )
}
```

### No Results (search/filter returned nothing)
- Confirm what they searched for
- Suggest clearing filters or trying different terms
- NEVER show a blank page with no explanation

### Error State (data failed to load)
- Explain something went wrong (not technical details)
- Offer a retry button
- If persistent, suggest contacting support

### Permission Denied
- Explain they don't have access
- Suggest who to contact or how to request access

## Checklist
- [ ] Every list/table has an empty state
- [ ] Search results have a "no results" state
- [ ] Dashboard sections show meaningful empty states (not blank)
- [ ] First-run experience guides the user to their first action
- [ ] Empty states are visually designed, not afterthoughts
