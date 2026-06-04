import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding, createComputed, onCleanup, For } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import Pango from "gi://Pango"
import AstalHyprland from "gi://AstalHyprland"
import AstalBattery from "gi://AstalBattery"
import AstalWp from "gi://AstalWp"
import AstalMpris from "gi://AstalMpris"
import AstalNetwork from "gi://AstalNetwork"
import GLib from "gi://GLib?version=2.0"
import { toggle as toggleCC, onVisibleChange as onCCVisible } from "./control-center"
import { toggle as toggleMedia, close as closeMedia } from "./media-window"
import { toggle as toggleCalendar } from "./calendar"

// ─── Workspaces ─────────────────────────────────────────────
function Workspaces() {
  const hypr = AstalHyprland.get_default()

  const buttons = Array.from({ length: 10 }, (_, i) => {
    const wsNum = i + 1
    return (
      <button
        onClicked={() => hypr.message(`dispatch hl.dsp.focus({ workspace = "${wsNum}" })`)}
        $={(self) => {
          function update() {
            const fw = hypr.focusedWorkspace
            const exists = hypr.workspaces.some((w) => w.id === wsNum)
            if (fw?.id === wsNum) {
              self.add_css_class("focused")
              self.remove_css_class("active")
            } else if (exists) {
              self.remove_css_class("focused")
              self.add_css_class("active")
            } else {
              self.remove_css_class("focused")
              self.remove_css_class("active")
            }
          }
          update()
          const id1 = hypr.connect("notify::focused-workspace", update)
          const id2 = hypr.connect("notify::workspaces", update)
          onCleanup(() => {
            hypr.disconnect(id1)
            hypr.disconnect(id2)
          })
        }}
      >
        <label class="ws-dot" label="●" />
      </button>
    )
  })

  return <box class="workspaces">{buttons}</box>
}

// ─── Focused Window Title ───────────────────────────────────
function FocusedWindow() {
  const hypr = AstalHyprland.get_default()

  const clientTitle = createComputed(() => {
    try {
      GLib.main_context_default().iteration(false)
      const client = createBinding(hypr, "focusedClient")()
      if (!client) return ""
      return createBinding(client, "title")() || ""
    } catch (_) { return "" }
  })

  return (
    <box class="focusedTitle" visible={createComputed(() => { try { GLib.main_context_default().iteration(false); return !!createBinding(hypr, "focusedClient")() } catch (_) { return false } })}>
      <label
        label={clientTitle}
        maxWidthChars={40}
        ellipsize={Pango.EllipsizeMode.END}
      />
    </box>
  )
}

// ─── Clock ──────────────────────────────────────────────────
function Clock() {
  const time = createPoll("", 1000, () => GLib.DateTime.new_now_local().format("%H:%M"))

  return (
    <button onClicked={toggleCalendar}>
      <box class="clock">
        <label label={time} />
      </box>
    </button>
  )
}

// ─── Mini Media Player (bar) ────────────────────────────────
function MiniMedia() {
  const mpris = AstalMpris.get_default()

  // Use a poll to continuously verify a player with a real title exists, ignoring ghosts
  const hasMedia = createPoll(false, 1000, () => {
    return mpris.players.length > 0 && mpris.players.some((p: any) => !!p.title)
  })

  // Auto-close the media window when playback stops
  onCleanup(hasMedia.subscribe(() => {
    if (!hasMedia.peek()) closeMedia()
  }))

  return (
    <box class="mini-media" visible={hasMedia}>
      <For each={createBinding(mpris, "players")}>
        {(player: any) => {
          const nowPlaying = createComputed(() => {
            try {
              GLib.main_context_default().iteration(false)
              const t = createBinding(player, "title")()
              const a = createBinding(player, "artist")()
              return t ? `${a ? a + " - " : ""}${t}` : ""
            } catch (_) { return "" }
          })
          return (
            <button onClicked={toggleMedia} visible={createBinding(player, "title")((t: string) => !!t)}>
              <box>
                <label
                  class="player-icon"
                  label={String.fromCodePoint(0xF075A)}
                />
                <label
                  class="now-playing"
                  label={nowPlaying}
                />
              </box>
            </button>
          )
        }}
      </For>
    </box>
  )
}

// ─── Volume Icon ────────────────────────────────────────────
function VolumeIcon() {
  const speaker = AstalWp.get_default()?.defaultSpeaker
  if (!speaker) return <box />

  return (
    <box class="volIcon">
      <image
        iconName={createBinding(speaker, "volumeIcon")}
        pixelSize={16}
        tooltipText={createBinding(speaker, "volume")(
          (v: number) => `${Math.floor((v || 0) * 100)}%`,
        )}
      />
    </box>
  )
}

// ─── Battery Icon ───────────────────────────────────────────
function BatteryIcon() {
  const battery = AstalBattery.get_default()

  const batIcon = createComputed(() => {
    try {
      GLib.main_context_default().iteration(false)
      const charging = createBinding(battery, "charging")()
      const pct = createBinding(battery, "percentage")()
      if (charging) return String.fromCodePoint(0x26A1) // ⚡ bolt
      if (pct < 0.15) return String.fromCodePoint(0xF244) // empty
      if (pct < 0.40) return String.fromCodePoint(0xF243) // quarter
      if (pct < 0.70) return String.fromCodePoint(0xF242) // half
      if (pct < 0.90) return String.fromCodePoint(0xF241) // three quarters
      return String.fromCodePoint(0xF240) // full
    } catch (_) { return String.fromCodePoint(0xF240) }
  })

  const batPct = createComputed(() => {
    try {
      GLib.main_context_default().iteration(false)
      const pct = createBinding(battery, "percentage")()
      return `${Math.floor((pct || 0) * 100)}%`
    } catch (_) { return "0%" }
  })

  return (
    <button class="battery" visible={createBinding(battery, "isPresent")}>
      <box spacing={6}>
        <label class="batIcon" label={batIcon} tooltipText={batPct} />
        <label class="batPercent" label={batPct} />
      </box>
    </button>
  )
}

// ─── Network Indicator ──────────────────────────────────────
function NetworkIndicator() {
  const network = AstalNetwork.get_default()

  return (
    <box class="netIcon">
      <label
        label={String.fromCodePoint(0xF05A9)}
        tooltipText={createBinding(network, "wifi")(
          (w: any) => w?.ssid || "Disconnected",
        )}
      />
    </box>
  )
}

// ─── Power Button ───────────────────────────────────────────
function PowerButton() {
  return (
    <button
      class="powerButton"
      onClicked={() => execAsync(["systemctl", "poweroff"])}
    >
      <label label={String.fromCodePoint(0xF0425)} tooltipText="Power Off" />
    </button>
  )
}

// ─── Control Center Toggle ──────────────────────────────────
function CCToggle() {
  let icon: Gtk.Label

  function syncIcon() {
    const cc = app.get_window("control-center")
    if (cc && icon) icon.label = cc.visible
      ? String.fromCodePoint(0xF0143) // nf-md-chevron_up
      : String.fromCodePoint(0xF0142) // nf-md-chevron_right
  }

  return (
    <button
      class="controlCenterButton"
      onClicked={() => {
        toggleCC()
        syncIcon()
      }}
      $={() => {
        // Subscribe to CC visibility from any source (click, Escape, programmatic)
        onCCVisible(() => syncIcon())
      }}
    >
      <label
        $={(self: any) => (icon = self)}
        label={String.fromCodePoint(0xF0142)}
      />
    </button>
  )
}

// ─── Main Bar Component ─────────────────────────────────────
export default function Bar({
  gdkmonitor,
}: {
  gdkmonitor: Gdk.Monitor
}) {
  let win: Astal.Window
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  onCleanup(() => win.destroy())

  return (
    <window
      $={(self: any) => (win = self)}
      visible
      namespace="bar"
      name={`bar-${gdkmonitor.connector}`}
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox>
        <box $type="start">
          <Workspaces />
          <FocusedWindow />
        </box>
        <box $type="center">
          <Clock />
          <MiniMedia />
        </box>
        <box $type="end" halign={Gtk.Align.END}>
          <CCToggle />
          <box class="rightBox">
            <VolumeIcon />
            <BatteryIcon />
            <NetworkIndicator />
            <PowerButton />
          </box>
        </box>
      </centerbox>
    </window>
  )
}
