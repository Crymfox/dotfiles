// Run an accessor that may throw (Astal proxies can throw while their
// D-Bus connection is still coming up) and fall back to a default.
export function safe<T>(fn: () => T, fallback: T): T {
  try { return fn() }
  catch (_) { return fallback }
}
