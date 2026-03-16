# Common Error Patterns

## Null / Undefined References

**Symptoms:** NullPointerException, TypeError: Cannot read properties of undefined, AttributeError: 'NoneType'

**Common Causes:**
- Uninitialized variable used before assignment
- Function returns null/undefined on error path
- Optional field accessed without null check
- Async operation not awaited, returns Promise instead of value
- Array access out of bounds

**Investigation:**
1. Find the exact variable that's null
2. Trace it back to where it should have been assigned
3. Check all code paths — is there one where assignment is skipped?
4. Check if it's a timing issue (async)

## Off-by-One Errors

**Symptoms:** Array index out of bounds, missing first/last element, loop runs one too many/few times

**Common Causes:**
- `<` vs `<=` in loop condition
- 0-indexed vs 1-indexed confusion
- Fence-post error (N items need N-1 separators)
- Substring/slice end index is exclusive

**Investigation:**
1. Check boundary conditions: what happens at index 0? At length-1? At length?
2. Manually trace the loop for 0, 1, and 2 elements
3. Check if the API uses inclusive or exclusive end indices

## Race Conditions

**Symptoms:** Intermittent failures, works in debugger but fails in production, different results each run

**Common Causes:**
- Shared mutable state without synchronization
- Check-then-act without atomic operation
- Relying on operation ordering without guarantees
- Stale closures capturing old values

**Investigation:**
1. Identify all shared mutable state
2. Check if access is synchronized (mutex, lock, atomic, channel)
3. Add logging with timestamps and thread/goroutine IDs
4. Use race detection tools (`go test -race`, Thread Sanitizer)

## Memory Leaks

**Symptoms:** Increasing memory usage over time, OOM errors, slow performance after running for a while

**Common Causes:**
- Event listeners added but never removed
- Cache growing without eviction policy
- Closures holding references to large objects
- Unclosed database connections, file handles, streams
- Circular references preventing garbage collection

**Investigation:**
1. Profile memory usage over time
2. Take heap snapshots at different points
3. Compare snapshots to find growing objects
4. Check for patterns: event handlers, closures, caches

## Deadlocks

**Symptoms:** Application hangs, no CPU usage, no logs after a certain point

**Common Causes:**
- Two threads/goroutines waiting for each other's locks
- Channel send/receive without matching counterpart
- Database transaction waiting for a lock held by another transaction

**Investigation:**
1. Get a thread dump / goroutine dump
2. Find blocked threads and what they're waiting for
3. Check lock ordering — is it consistent?
4. Check for unbuffered channels with no receiver

## Serialization Issues

**Symptoms:** Wrong types after JSON parse, missing fields, date format errors, encoding issues

**Common Causes:**
- JSON number precision loss (large integers in JavaScript)
- Date/time timezone handling (UTC vs local)
- Character encoding mismatch (UTF-8 vs Latin-1)
- Missing fields silently becoming null/undefined
- Case sensitivity in field names

**Investigation:**
1. Log the raw serialized data (before parse)
2. Compare expected vs actual types
3. Check for implicit type conversions
4. Verify both sides agree on field names and types

## Connection / Timeout Errors

**Symptoms:** ECONNREFUSED, timeout errors, intermittent 5xx responses

**Common Causes:**
- Target service not running
- Wrong host/port configuration
- Connection pool exhausted
- Network/firewall blocking
- DNS resolution failure
- TLS certificate issues

**Investigation:**
1. Verify target service is running and accessible
2. Check configuration (host, port, protocol)
3. Monitor connection pool metrics
4. Check for connection leaks (opened but not closed)
5. Test connectivity with curl/telnet
