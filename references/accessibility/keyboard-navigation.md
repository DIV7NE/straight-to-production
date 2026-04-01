# Keyboard Navigation

## Core Rules
- Every interactive element MUST be reachable by Tab key
- Tab order MUST follow visual/logical order (use DOM order, avoid `tabIndex` > 0)
- Focus indicator MUST be visible on every focusable element
- Never use `outline: none` without providing an alternative focus style

## Focus Management

### Skip Link (first focusable element on page)
```tsx
<a href="#main-content" className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:p-2 focus:bg-white">
  Skip to main content
</a>
<main id="main-content">...</main>
```

### Modal Focus Trapping
When a modal opens:
1. Move focus to the modal (or its first focusable element)
2. Trap Tab/Shift+Tab within the modal
3. Close on Escape
4. Return focus to the trigger element on close

shadcn/ui Dialog component handles this automatically.

### Focus After Route Navigation
After SPA navigation, move focus to the main heading or content area.

## Common Patterns
- Dropdown menus: Arrow keys to navigate, Enter to select, Escape to close
- Tabs: Arrow keys to switch tabs, Tab to enter tab content
- Accordion: Enter/Space to toggle, arrow keys to navigate between headers
- Tooltips: Show on focus (not just hover)

## Testing
1. Unplug your mouse
2. Tab through the entire application
3. Can you reach everything? Is focus always visible? Can you complete all tasks?
4. Check: no keyboard traps (can you always Tab away?)
