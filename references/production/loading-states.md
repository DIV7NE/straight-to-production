# Loading States for Production

## Principle
Users should NEVER stare at a blank screen or wonder if something is happening. Every async operation needs a visible loading indicator.

## Page-Level Loading (app/loading.tsx)
```typescript
export default function Loading() {
  return <PageSkeleton />
}
```
Next.js automatically wraps pages in Suspense and shows this during navigation.

## Component-Level Suspense
```tsx
import { Suspense } from 'react'

export default function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel />
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <RecentActivity />
      </Suspense>
    </div>
  )
}
```

## Skeleton Screens (preferred over spinners)
- Match the layout of the content being loaded
- Use `animate-pulse` (Tailwind) for the shimmer effect
- Show the shape of content: rectangles for text, circles for avatars, cards for cards
- NEVER show a generic spinner for content that has a known layout

## Button Loading States
```tsx
const [isPending, startTransition] = useTransition()

<button
  disabled={isPending}
  onClick={() => startTransition(() => action())}
>
  {isPending ? 'Saving...' : 'Save'}
</button>
```

## Optimistic Updates
For actions where the result is predictable (like/unlike, toggle, add to list):
```tsx
const [optimisticItems, addOptimistic] = useOptimisticAction(items)
```
Show the result immediately, revert if the server action fails.

## Checklist
- [ ] Every page has a loading.tsx or Suspense boundary
- [ ] Skeleton screens match content layout (not generic spinners)
- [ ] Buttons show loading state during async operations
- [ ] Form submissions disable the submit button and show progress
- [ ] Optimistic updates for predictable actions
- [ ] Never show blank screen during data fetching
