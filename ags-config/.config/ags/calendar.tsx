import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Gio from "gi://Gio"
import GLib from "gi://GLib?version=2.0"
import { createState } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import { createPopup } from "./popup"

const CLOSE_DELAY = 400

const popup = createPopup("calendar", CLOSE_DELAY)
export const toggle = popup.toggle
export const isVisible = popup.isVisible
export const onVisibleChange = popup.onVisibleChange

// ─── Date & Time ────────────────────────────────────────────
function DateAndTime() {
  // GLib.DateTime — zero process forks, instant at startup
  const dateStr = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format("%A, %B %d, %Y"))
  const timeStr = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format("%-k:%M:%S"))

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
  let fetched = false
  let lastPath: string | null = null

  function fetchImage() {
    setImagePath("") // Revert to placeholder background while loading
    // Timestamped name busts GTK's CSS url() cache; delete the previous one so
    // /tmp doesn't accumulate images
    const path = `/tmp/calendar-img-${Date.now()}.jpg`
    // Use -L to follow redirects (picsum.dev redirects to the actual image host)
    execAsync(["curl", "-s", "-L", "-o", path, "https://picsum.dev/250/200"])
      .then(() => {
        if (lastPath) Gio.File.new_for_path(lastPath).delete_async(GLib.PRIORITY_DEFAULT, null, null)
        lastPath = path
        const file = Gio.File.new_for_path(path)
        setImagePath(file.get_uri())
      })
      .catch((err) => console.error("Failed to fetch image:", err))
  }

  return (
    <button
      onClicked={fetchImage}
      // Defer first fetch to first calendar open — network calls at startup can freeze
      $={() => {
        onVisibleChange((vis) => {
          if (vis && !fetched) { fetched = true; fetchImage() }
        })
      }}
    >
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
        $={(self) => { popup.setRevealer(self) }}
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
