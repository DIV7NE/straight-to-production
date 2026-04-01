# Loading States for Production

## Principle
Users should NEVER stare at a blank screen or wonder if something is happening. Every async operation needs a visible loading indicator.

## Types of Loading States

### Page/Screen Loading
When navigating to a new page or screen:
- Show a skeleton screen that matches the content layout
- NOT a generic spinner — skeletons tell users what's coming
- Web: loading.tsx / Suspense boundaries / route-level loaders
- Mobile: placeholder views matching the content shape
- Desktop: skeleton panels in the layout

### Component Loading
When a section of a page loads independently:
- Wrap in a loading boundary (Suspense, loading component)
- Show skeleton that matches the component's shape
- Load independently so the rest of the page is interactive

### Action Loading (Buttons, Forms)
When the user triggers an action:
- Disable the button immediately (prevents double-submit)
- Change button text: "Save" → "Saving..."
- Re-enable on completion or error
- Show success/error feedback

### Data Refresh
When background data updates:
- Use optimistic updates for predictable actions (like/unlike, toggle)
- Show the expected result immediately
- Revert if the server action fails
- Use stale-while-revalidate for data that can be slightly outdated

## Skeleton Screens
- Match the layout of the content being loaded
- Use animated shimmer/pulse effect
- Show shapes: rectangles for text, circles for avatars, cards for cards
- NEVER show a generic spinner for content with a known layout

## Checklist
- [ ] Every page/screen has a loading state
- [ ] Skeleton screens match content layout
- [ ] Buttons show loading state during async operations
- [ ] Form submissions disable the submit button
- [ ] Optimistic updates for predictable actions
- [ ] No blank screens during data fetching
