---
name: frontend-patterns
description: "React and Next.js technical patterns — composition, hooks, state management, performance, and accessibility. Auto-loaded when working with React components, custom hooks, or Next.js pages."
disable-model-invocation: false
user-invocable: false
---

# Frontend Technical Patterns

Domain knowledge for React/Next.js component architecture, state management, and performance. Follow these conventions when implementing frontend features.

## Component Composition

- Prefer composition over inheritance — build from small, focused components
- Compound components share implicit state via Context for related UI groups (Tabs, Accordion, Menu)
- Compound component children must validate their context: `if (!ctx) throw new Error('Child must be used within Parent')`
- Keep component files under 200 lines — extract sub-components and hooks when growing
- Co-locate component, styles, types, and tests in the same directory
- Export compound component parts as named exports from a barrel file

## Custom Hooks

- Extract reusable logic into `use*` hooks — one concern per hook
- Return tuples `[value, setter]` for simple state, objects `{ data, loading, error }` for complex
- Accept options objects for configurability: `useDebounce(value, { delay: 300 })`
- Stabilize callbacks with `useCallback` and derived values with `useMemo` inside hooks
- Always clean up side effects — return cleanup functions from `useEffect`
- Name hooks after what they provide: `useAuth`, `useMediaQuery`, `useIntersectionObserver`

## State Management

- **Local state** (`useState`): UI-only state — toggles, form inputs, active tabs
- **Context + Reducer**: Shared state within a feature boundary — keeps related actions and state co-located
- **External stores** (Zustand, Jotai): Cross-feature or global state — auth, theme, notifications
- Avoid prop drilling past 2 levels — lift to Context or external store
- Keep server state in a data-fetching library (React Query, SWR) — never duplicate in local state
- Derive values instead of syncing state: compute `filteredItems` from `items` + `filter`, don't store separately

## Performance

- `React.memo` only on components that re-render with unchanged props — profile before applying
- `useMemo` for expensive computations (sorting, filtering large lists), not for simple object creation
- `useCallback` for functions passed as props to memoized children
- Lazy-load heavy components: `const Chart = lazy(() => import('./Chart'))` with `<Suspense fallback={<Skeleton />}>`
- Virtualize lists over ~100 items with `@tanstack/react-virtual` — set `overscan: 5` for smooth scrolling
- Split bundles at route boundaries in Next.js — use `next/dynamic` with `ssr: false` for client-only components
- Avoid anonymous objects/arrays as props: `style={{ color: 'red' }}` creates new references every render

## Error Boundaries

- Wrap feature sections (not the entire app) in error boundaries for granular recovery
- Provide a retry mechanism in fallback UI — reset the error state and re-mount children
- Log errors to monitoring service in `componentDidCatch`
- Use `react-error-boundary` package for functional component support with `useErrorBoundary` hook
- Error boundaries do not catch: event handlers, async code, SSR errors — handle those with try/catch

## Form Handling

- Use controlled components for forms that need real-time validation or conditional logic
- Prefer form libraries (React Hook Form, Formik) for complex forms — avoid reinventing validation
- Validate with schema libraries (Zod, Yup) — share schemas between frontend and API
- Show field-level errors inline, form-level errors at the top
- Disable submit button during submission, show loading state
- Reset form state on successful submission, preserve on error

## Data Fetching

- Use React Query / SWR for server state — they handle caching, deduplication, and revalidation
- Set `staleTime` based on data volatility: 0 for real-time, 60s for semi-static, 5m+ for reference data
- Prefetch data on hover or route transition for perceived performance
- Use optimistic updates for user-initiated mutations — rollback on error
- Handle loading, error, and empty states explicitly in every data-fetching component

## Accessibility

- Every interactive element must be keyboard-accessible — test with Tab, Enter, Escape, Arrow keys
- Use semantic HTML: `<button>` not `<div onClick>`, `<nav>`, `<main>`, `<article>`
- Add ARIA attributes only when semantic HTML is insufficient: `role`, `aria-label`, `aria-expanded`
- Manage focus on route changes and modal open/close — trap focus inside modals
- Support `prefers-reduced-motion` for animations — disable or simplify transitions
- Ensure color contrast ratios meet WCAG AA: 4.5:1 for text, 3:1 for large text and UI components
- Test with screen reader (VoiceOver, NVDA) for critical user flows

## Next.js Specifics

- Use Server Components by default — add `'use client'` only when needing hooks, event handlers, or browser APIs
- Fetch data in Server Components or `generateStaticParams` — avoid `useEffect` for initial data
- Use `loading.tsx` and `error.tsx` for route-level loading/error states
- Prefer `next/image` for automatic optimization, lazy loading, and responsive sizing
- Use `next/link` for client-side navigation with prefetching
- Keep API routes thin — validate input, call service layer, return response
