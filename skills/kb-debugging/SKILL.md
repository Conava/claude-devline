---
name: kb-debugging
description: Domain logic for systematic debugging — injected into the debugger agent. Provides common bug patterns and debugging tools reference. Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# Debugging Reference

Supplementary reference for the debugger agent. The core scientific debugging process (Reproduce → Evidence → Hypothesize → Test → Fix → Verify) is defined in the agent itself — this skill provides pattern recognition and tooling guidance.

## Common Bug Patterns

### Off-by-One Errors
- Check loop boundaries, array indices, fence-post conditions
- Look for `<` vs `<=`, `i` vs `i+1`

### Null/Undefined References
- Trace the variable back to its origin
- Check all paths — is there a code path where it's never assigned?
- Look for async gaps where state can change

### Race Conditions
- Look for shared mutable state accessed from multiple threads/goroutines/processes
- Check for missing locks, atomic operations, or synchronization
- Add ordering guarantees or make state immutable

### State Management
- Check if state is being mutated where it shouldn't be
- Look for stale closures, cached values, or shallow copies
- Verify state transitions are valid

### Integration Issues
- Check API contracts — is the caller sending what the callee expects?
- Verify serialization/deserialization (JSON types, date formats, encoding)
- Check network timeouts, retries, and error handling

## Debugging Tools

- **Logging** — Add targeted, temporary log statements at key decision points
- **Debugger** — Set breakpoints at suspicious locations, inspect state
- **Git bisect** — Find the exact commit that introduced the bug
- **Profiler** — For performance bugs, identify bottlenecks
- **Network tools** — For API issues, inspect request/response payloads

## Additional Resources

### Reference Files

- **`references/debugging-tools.md`** — Language-specific debuggers, profilers, and diagnostic tools
- **`references/common-errors.md`** — Common error patterns by language and framework
