# Web Frontend Patterns

Use context7 MCP to look up current API documentation for any framework mentioned here.

## React Patterns

### Component Structure
- Functional components with hooks (no class components)
- Custom hooks for shared logic (`useAuth`, `useForm`, `useFetch`)
- Container/presentation split for complex components
- Error boundaries for graceful error handling

### State Management
- Local state: `useState` for component-specific state
- Shared state: Context API for small apps, Zustand/Redux for large apps
- Server state: React Query / TanStack Query for data fetching
- URL state: React Router for navigation-dependent state

### Performance
- `React.memo()` for expensive pure components
- `useMemo()` for expensive computations
- `useCallback()` for stable function references passed to children
- Lazy loading: `React.lazy()` + `Suspense` for route-level code splitting

## Vue Patterns

### Composition API
- `setup()` with `ref()`, `reactive()`, `computed()`
- Composables for shared logic (`useAuth`, `useForm`)
- `defineProps()` and `defineEmits()` for component API
- `<script setup>` for concise SFCs

### State Management
- Pinia for global state (replaces Vuex)
- Composables for shared reactive state
- `provide/inject` for dependency injection

## Angular Patterns

### Architecture
- Feature modules with lazy loading
- Smart (container) vs presentational components
- Services for business logic and data access
- RxJS for async operations

### State
- NgRx for complex state management
- Simple services with BehaviorSubject for smaller apps

## Svelte Patterns

### Reactivity
- Reactive declarations with `$:`
- Stores for shared state (`writable`, `readable`, `derived`)
- Component composition with slots
- Actions for reusable DOM behavior

## CSS / Styling

### Approaches
- **Utility-first (Tailwind):** Compose utilities in markup, extract components for repetition
- **CSS Modules:** Scoped class names, no global conflicts
- **CSS-in-JS (styled-components):** Co-located styles with dynamic props
- **BEM:** Block__Element--Modifier naming for vanilla CSS

### Responsive Patterns
```css
/* Mobile-first breakpoints */
.container { padding: 1rem; }
@media (min-width: 768px) { .container { padding: 2rem; } }
@media (min-width: 1024px) { .container { max-width: 1200px; margin: 0 auto; } }
```

### Dark Mode
```css
:root { --bg: #ffffff; --text: #1a1a1a; }
@media (prefers-color-scheme: dark) {
  :root { --bg: #1a1a1a; --text: #f0f0f0; }
}
```
