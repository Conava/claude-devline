---
name: jdtls-lsp
description: "Eclipse JDT.LS (Java language server) guidance for code intelligence and refactoring. Auto-loaded when working with .java files alongside java-coding-standards."
disable-model-invocation: false
user-invocable: false
allowed-tools: Bash
---

# Eclipse JDT.LS Integration

Guidance for leveraging the Java language server for code intelligence.

## Supported File Types

`.java`

## Installation

```bash
# macOS
brew install jdtls
```

Requires Java 17+.

## JDT.LS Specific Guidance

### Build System Integration
- Maven: reads `pom.xml` for dependencies and classpath
- Gradle: reads `build.gradle` / `build.gradle.kts`
- Ensure build files are valid for accurate analysis

### Key Code Actions
- Organize imports
- Generate constructors, getters, setters, equals/hashCode, toString
- Extract method, variable, constant
- Inline variable/method
- Convert to enhanced for loop, try-with-resources, switch expression

### Diagnostics
- Compilation errors and warnings from the Java compiler
- Null analysis annotations (`@Nullable`, `@NonNull`)
- Deprecation warnings
- Unused code detection

### Performance
- Large projects: ensure `.classpath` and `.project` files are correct
- Use `java.import.exclusions` to exclude unnecessary paths
- Incremental compilation for fast feedback
