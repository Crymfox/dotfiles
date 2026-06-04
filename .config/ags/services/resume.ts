import app from "ags/gtk4/app"
import Gio from "gi://Gio"
import GLib from "gi://GLib?version=2.0"

/**
 * Listen for logind PrepareForSleep to restart AGS after resume.
 * Astal D-Bus proxies don't reconnect when system services restart.
 * Instead of a complex reconnect system, cleanly restart the process.
 */
export function watchResume() {
  try {
    const proxy = Gio.DBusProxy.new_sync(
      Gio.DBus.system,
      Gio.DBusProxyFlags.NONE,
      null,
      "org.freedesktop.login1",
      "/org/freedesktop/login1",
      "org.freedesktop.login1.Manager",
      null,
    )

    proxy.connect("g-signal", (_p: any, _s: string, signal: string, params: GLib.Variant | null) => {
      if (signal !== "PrepareForSleep") return
      const sleeping = params?.get_child_value(0)?.get_boolean()
      if (sleeping !== false) return

      console.log("Resume detected — restarting AGS")
      GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
        app.quit(0)
        return GLib.SOURCE_REMOVE
      })
    })

    console.log("Resume watcher active")
  } catch (e) {
    console.error("Resume watcher failed:", e)
  }
}
