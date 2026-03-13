# Mobile Development Patterns

Use context7 MCP to look up current API documentation for any framework mentioned here.

## Flutter

### Widget Structure
- Stateless widgets for static UI
- Stateful widgets only when local state is needed
- `const` constructors for performance
- Extract widgets into separate files when > 100 lines

### State Management
- Provider/Riverpod for dependency injection and state
- BLoC pattern for complex business logic
- `ValueNotifier` for simple reactive values

### Navigation
- GoRouter for declarative routing
- Named routes for deep linking
- Bottom navigation with `IndexedStack` for tab persistence

### Performance
- Use `const` wherever possible
- `ListView.builder` for long lists (not `Column` with many children)
- Cache images with `cached_network_image`
- Profile with Flutter DevTools

## SwiftUI

### View Structure
- Small, composable views
- `@State` for view-local state
- `@Binding` for child-to-parent communication
- `@ObservedObject` / `@StateObject` for external state
- `@EnvironmentObject` for app-wide state

### Architecture
- MVVM with ObservableObject view models
- Combine for reactive data streams
- Swift Concurrency (async/await) for networking

### Navigation
- `NavigationStack` (iOS 16+) for programmatic navigation
- `NavigationSplitView` for iPad/macOS adaptive layouts

## Jetpack Compose (Android/Kotlin)

### Composable Functions
- Stateless composables with parameters
- `remember` / `rememberSaveable` for local state
- State hoisting: pass state up, events down
- `LaunchedEffect` for side effects

### Architecture
- MVVM with ViewModel and StateFlow
- Hilt for dependency injection
- Repository pattern for data access

### Navigation
- Compose Navigation for screen transitions
- Type-safe route arguments
- Bottom navigation with `NavHost`

### Material Design 3
- Material You dynamic color theming
- Follow Material 3 component guidelines
- Use `Scaffold`, `TopAppBar`, `FloatingActionButton`

## Cross-Platform Considerations

### Shared Patterns
- Consistent navigation paradigms per platform
- Platform-specific gestures (swipe-to-delete iOS, long-press Android)
- Adaptive layouts for different screen sizes
- Respect platform conventions (back button Android, swipe back iOS)

### Touch Targets
- iOS: minimum 44x44pt
- Android: minimum 48x48dp
- Adequate spacing between interactive elements
