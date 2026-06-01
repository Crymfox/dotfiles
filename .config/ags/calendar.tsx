import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Gio from "gi://Gio"
import { createState } from "ags"
import { createPoll } from "ags/time"
import { timeout } from "ags/time"
import { execAsync } from "ags/process"

const CLOSE_DELAY = 400

// ─── Toggle helper ──────────────────────────────────────────
let revealer: Gtk.Revealer | null = null

export function toggle() {
  const win = app.get_window("calendar")
  if (!win) return

  if (win.visible) {
    if (revealer) {
      revealer.revealChild = false
      timeout(CLOSE_DELAY, () => {
        win.visible = false
      })
    }
  } else {
    win.visible = true
    timeout(10, () => {
      if (revealer) revealer.revealChild = true
    })
  }
}

// ─── Date & Time ────────────────────────────────────────────
function DateAndTime() {
  const dateStr = createPoll("", 1000, "date '+%A, %B %d, %Y'")
  const timeStr = createPoll("", 1000, "date '+%k:%M:%S'")

  return (
    <box class="date-and-time" orientation={Gtk.Orientation.VERTICAL}>
      <label class="date" label={dateStr} />
      <label class="big-clock" label={timeStr} />
    </box>
  )
}

// ─── Cat Image ──────────────────────────────────────────────
function CatImage() {
  const [imagePath, setImagePath] = createState("")

  function fetchImage() {
    setImagePath("") // Revert to placeholder background while loading
    const path = `/tmp/calendar-img-${Date.now()}.jpg`
    // Use -L to follow redirects (picsum.photos redirects to the actual image host)
    execAsync(["curl", "-s", "-L", "-o", path, "https://picsum.photos/250/200"])
      .then(() => {
        const file = Gio.File.new_for_path(path)
        setImagePath(file.get_uri())
      })
      .catch((err) => console.error("Failed to fetch image:", err))
  }

  // Fetch the first image when the widget loads
  fetchImage()

  return (
    <button onClicked={fetchImage}>
      <box
        class="cat"
        css={imagePath((uri) => uri ? `background-image: url('${uri}');` : "")}
      />
    </button>
  )
}

// ─── Calendar ───────────────────────────────────────────────
function CalendarWidget() {
  return (
    <box class="calendar-container" spacing={24}>
      <box orientation={Gtk.Orientation.VERTICAL} spacing={12}>
        <DateAndTime />
        <CatImage />
      </box>
      <Gtk.Calendar />
    </box>
  )
}

// ─── Main Calendar Window ───────────────────────────────────
export default function Calendar() {
  const { TOP } = Astal.WindowAnchor

  return (
    <window
      $={(self) => {
        const ctrl = new Gtk.EventControllerKey()
        ctrl.connect("key-pressed", (_ctrl, keyval) => {
          if (keyval === Gdk.KEY_Escape) toggle()
        })
        self.add_controller(ctrl)
      }}
      visible={false}
      name="calendar"
      namespace="calendar"
      class="Calendar"
      anchor={TOP}
      application={app}
      keymode={Astal.Keymode.ON_DEMAND}
    >
      <revealer
        $={(self) => { revealer = self }}
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        transitionDuration={CLOSE_DELAY}
        revealChild={false}
      >
        <box class="calendar-window">
          <CalendarWidget />
        </box>
      </revealer>
    </window>
  )
}
