# Desktop Development Patterns

Use context7 MCP to look up current API documentation for any framework mentioned here.

## JavaFX

### Architecture
- MVC or MVVM pattern
- FXML for layout, controllers for logic
- CSS for styling (`-fx-` prefixed properties)
- Scene graph hierarchy

### Layout
- `VBox`, `HBox` for linear layouts
- `GridPane` for grid layouts
- `BorderPane` for header/sidebar/content/footer
- `AnchorPane` for absolute positioning (use sparingly)

### Best Practices
- Separate FXML and controller logic
- Use CSS for all visual styling
- Bind properties for reactive updates
- Use `Platform.runLater()` for UI updates from background threads
- `Task` and `Service` for background operations

### Example Structure
```
src/main/
├── java/com/example/
│   ├── App.java
│   ├── controllers/
│   ├── models/
│   └── services/
├── resources/
│   ├── fxml/
│   ├── css/
│   └── images/
```

## Electron

### Architecture
- Main process (Node.js) handles system interactions
- Renderer process (Chromium) handles UI
- IPC for communication between processes
- Preload scripts for secure API exposure

### Security
- Enable `contextIsolation: true`
- Disable `nodeIntegration` in renderer
- Use `contextBridge` for safe API exposure
- Validate all IPC messages
- CSP headers for renderer content

### Performance
- Lazy load windows and heavy modules
- Use web workers for CPU-intensive tasks
- Minimize IPC traffic
- Profile with Chromium DevTools

## Tauri

### Architecture
- Rust backend for system operations
- Web frontend (any framework) for UI
- Commands for Rust ↔ JS communication
- Event system for async notifications

### Security
- Allowlist for API access (file system, HTTP, shell)
- Content Security Policy
- No Node.js in frontend (smaller attack surface)
- Validate all command arguments in Rust

### Advantages over Electron
- Smaller bundle size (uses system webview)
- Lower memory footprint
- Rust backend for performance-critical operations
- Better security model

## Cross-Platform Desktop

### Window Management
- Support window resize with minimum dimensions
- Remember window position and size
- Support multiple monitors
- Handle DPI scaling (Retina/HiDPI)

### Keyboard
- Standard shortcuts (Ctrl/Cmd+C/V/X/Z/S)
- Menu bar with keyboard accelerators
- Tab navigation for forms
- Escape to close dialogs

### Native Feel
- Use platform-native file dialogs
- Follow OS-specific menu conventions
- Support drag and drop where appropriate
- System tray integration for background apps
