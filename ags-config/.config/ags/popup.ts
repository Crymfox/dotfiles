import app from "ags/gtk4/app"
import { Gtk } from "ags/gtk4"
import { timeout } from "ags/time"

// Shared scaffolding for popup windows (calendar, media, control-center).
// Windows with a Gtk.Revealer get a slide animation on toggle; windows
// without one just flip visibility.
export function createPopup(name: string, closeDelay = 350) {
  let revealer: Gtk.Revealer | null = null

  function toggle() {
    const win = app.get_window(name)
    if (!win) return

    if (win.visible) {
      if (revealer) {
        revealer.revealChild = false
        timeout(closeDelay, () => {
          win.visible = false
        })
      } else {
        win.visible = false
      }
    } else {
      win.visible = true
      if (revealer) {
        timeout(10, () => {
          if (revealer) revealer.revealChild = true
        })
      }
    }
  }

  function close() {
    const win = app.get_window(name)
    if (win) win.visible = false
  }

  function isVisible() {
    const win = app.get_window(name)
    return win ? win.visible : false
  }

  // Fires whenever the window is shown/hidden from any source (click,
  // Escape, programmatic toggle). Retries while the window isn't created yet.
  function onVisibleChange(fn: (visible: boolean) => void, retries = 50): () => void {
    let unsub: () => void = () => {}

    function attach(left: number) {
      const win = app.get_window(name)
      if (!win) {
        if (left <= 0) return
        const timer = timeout(100, () => attach(left - 1))
        unsub = () => timer.cancel()
        return
      }
      const id = win.connect("notify::visible", () => fn(win.visible))
      unsub = () => win.disconnect(id)
    }

    attach(retries)
    return () => unsub()
  }

  return {
    setRevealer: (r: Gtk.Revealer) => { revealer = r },
    toggle,
    close,
    isVisible,
    onVisibleChange,
  }
}
