import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Gio from "gi://Gio"
import Pango from "gi://Pango"
import { createBinding, For } from "ags"
import { timeout, createPoll } from "ags/time"
import AstalMpris from "gi://AstalMpris"

const CLOSE_DELAY = 350

// ─── Toggle helper ──────────────────────────────────────────
let revealer: Gtk.Revealer | null = null

export function close() {
  const win = app.get_window("media")
  if (!win) return
  win.visible = false
}

export function toggle() {
  const win = app.get_window("media")
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

// ─── Helpers ────────────────────────────────────────────────
function lengthStr(length: number) {
  const l = length || 0
  const min = Math.floor(l / 60)
  const sec = Math.floor(l % 60)
  return `${min}:${sec < 10 ? "0" : ""}${sec}`
}

// ─── Track Info ─────────────────────────────────────────────
function TrackInfo({ player }: { player: AstalMpris.Player }) {
  return (
    <box class="track-info" orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER}>
      <label
        class="track-name"
        label={createBinding(player, "title")}
        justify={Gtk.Justification.CENTER}
        maxWidthChars={25}
        ellipsize={Pango.EllipsizeMode.END}
      />
      <label
        class="artist-name"
        label={createBinding(player, "artist")}
        justify={Gtk.Justification.CENTER}
        maxWidthChars={30}
        ellipsize={Pango.EllipsizeMode.END}
      />
    </box>
  )
}

// ─── Cover Art ──────────────────────────────────────────────
function CoverArt({ player }: { player: AstalMpris.Player }) {
  const coverCss = createBinding(player, "coverArt")((cover) => {
    const path = cover || player.artUrl
    if (!path) return ""
    try {
      // Properly encode the path to a valid URI so the CSS engine doesn't reject spaces
      const file = path.startsWith("file://") || path.startsWith("http")
        ? Gio.File.new_for_uri(path)
        : Gio.File.new_for_path(path)

      return `background-image: url('${file.get_uri()}');`
    } catch (_) {
      return ""
    }
  })

  return (
    <box
      class="cover-art"
      halign={Gtk.Align.CENTER}
      widthRequest={260}
      heightRequest={200}
      css={coverCss}
    />
  )
}

// ─── Position Slider ────────────────────────────────────────
function PositionSlider({ player }: { player: AstalMpris.Player }) {
  // MPRIS doesn't emit signals on every second while playing. We have to poll it.
  const position = createPoll(player.position, 1000, () => player.position)

  return (
    <box orientation={Gtk.Orientation.VERTICAL}>
      <slider
        class="position-slider"
        hexpand={true}
        drawValue={false}
        value={position((pos) => (player.length > 0 ? pos / player.length : 0))}
        onChangeValue={({ value }) => {
          player.position = player.length * value
        }}
      />
      <box class="position-label" hexpand={true}>
        <label
          label={position((pos) => lengthStr(pos))}
          halign={Gtk.Align.START}
          hexpand={true}
        />
        <label
          label={createBinding(player, "length")(
            (len) => lengthStr(len),
          )}
          halign={Gtk.Align.END}
          hexpand={true}
        />
      </box>
    </box>
  )
}

// ─── Controls ───────────────────────────────────────────────
function Controls({ player }: { player: AstalMpris.Player }) {
  return (
    <box class="media-controls" halign={Gtk.Align.CENTER} spacing={8}>
      <button
        class="media-btn"
        visible={createBinding(player, "canGoPrevious")}
        onClicked={() => player.previous()}
      >
        <image iconName="go-previous-symbolic" pixelSize={18} />
      </button>
      <button
        class="play-pause"
        visible={createBinding(player, "canControl")}
        onClicked={() => player.play_pause()}
      >
        <image
          iconName={createBinding(player, "playbackStatus")(
            (s) => s === AstalMpris.PlaybackStatus.PLAYING
              ? "media-playback-pause-symbolic"
              : "media-playback-start-symbolic",
          )}
          pixelSize={22}
        />
      </button>
      <button
        class="media-btn"
        visible={createBinding(player, "canGoNext")}
        onClicked={() => player.next()}
      >
        <image iconName="go-next-symbolic" pixelSize={18} />
      </button>
    </box>
  )
}

// ─── Main Media Window ──────────────────────────────────────
export default function MediaWindow() {
  const mpris = AstalMpris.get_default()
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
      name="media"
      namespace="media"
      class="MediaWindow"
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
        <box class="media-window" orientation={Gtk.Orientation.VERTICAL}>
          <For each={createBinding(mpris, "players")}>
            {(player) => (
              <box orientation={Gtk.Orientation.VERTICAL}>
                <CoverArt player={player} />
                <TrackInfo player={player} />
                <PositionSlider player={player} />
                <Controls player={player} />
              </box>
            )}
          </For>
        </box>
      </revealer>
    </window>
  )
}
