import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding, createComputed, createState, For, onCleanup } from "ags"
import { createPoll, timeout } from "ags/time"
import { execAsync } from "ags/process"
import Pango from "gi://Pango"
import AstalBattery from "gi://AstalBattery"
import AstalWp from "gi://AstalWp"
import AstalNetwork from "gi://AstalNetwork"
import AstalBluetooth from "gi://AstalBluetooth"
import Brightness from "./services/brightness"
import GLib from "gi://GLib?version=2.0"

const CLOSE_DELAY = 350

// ─── Toggle helper ──────────────────────────────────────────

export function toggle() {
  const win = app.get_window("control-center")
  if (!win) return
  win.visible = !win.visible
}

// Subscribe to visibility changes — fires whenever the CC window is
// shown/hidden from any source (click, Escape, programmatic toggle).
// Retries with a short delay if the window hasn't been created yet.
export function onVisibleChange(fn: (visible: boolean) => void, retries = 50): () => void {
  const win = app.get_window("control-center")
  if (!win) {
    if (retries <= 0) return () => {}
    const timer = timeout(100, () => {
      timer.cancel()
      return onVisibleChange(fn, retries - 1)
    })
    return () => timer.cancel()
  }
  const id = win.connect("notify::visible", () => fn(win.visible))
  return () => win.disconnect(id)
}

function forceResize() {
  const win = app.get_window("control-center")
  if (!win) return
  timeout(10, () => {
    win.set_size_request(0, 0)
    win.queue_resize()
    win.queue_allocate()
    // Nudge margin to force layer-shell renegotiation
    const m = win.marginRight
    win.marginRight = m + 1
    timeout(5, () => {
      if (!win) return
      win.marginRight = m
      win.queue_resize()
    })
  })
}

// ─── Header ─────────────────────────────────────────────────
function Header() {
  const battery = AstalBattery.get_default()
  const uptime = createPoll("", 60000, () => {
    // Use execAsync to avoid blocking the GLib main loop
    // Reading /proc/uptime synchronously at startup was a major freeze cause
    return execAsync("cat /proc/uptime").then((line) => {
      const mins = Number.parseInt(line.split(".")[0]) / 60
      if (mins > 18 * 60) return "Go Sleep"
      const h = Math.floor(mins / 60)
      const s = Math.floor(mins % 60)
      return `${h}:${s < 10 ? "0" + s : s}`
    }).catch(() => "")
  })

  return (
    <box class="header" spacing={8}>
      <label class="uptime" label={uptime((v) => `Uptime ${v}`)} />
      <box hexpand={true} />
      <label class="batIconCC" label={String.fromCodePoint(0xF142B)} visible={createBinding(battery, "isPresent")} />
      <label class="batPercentCC" label={createBinding(battery, "percentage")((p: number) => `${Math.floor((p || 0) * 100)}%`)} visible={createBinding(battery, "isPresent")} />
      <button onClicked={() => execAsync(["systemctl", "suspend"])} tooltipText="Sleep">
        <label label={String.fromCodePoint(0xF0FC6)} />
      </button>
      <button onClicked={() => execAsync(["systemctl", "poweroff"])} tooltipText="Power Off">
        <label label={String.fromCodePoint(0xF011)} />
      </button>
    </box>
  )
}

// ─── Volume Slider ──────────────────────────────────────────
function VolumeSlider() {
  const speaker = AstalWp.get_default()?.defaultSpeaker
  if (!speaker) return <box />

  return (
    <box>
      <button>
        <label label={createBinding(speaker, "mute")(() => {
          if (speaker.mute) return String.fromCodePoint(0xF0581) // volume_off
          const v = speaker.volume * 100
          if (v >= 34) return String.fromCodePoint(0xF057E) // volume_high
          return String.fromCodePoint(0xF057E) // volume_high (no low icon available)
        })} />
      </button>
      <slider
        class="volBar"
        hexpand={true}
        value={createBinding(speaker, "volume")}
        onChangeValue={({ value }) => {
          speaker.set_volume(value)
          return false
        }}
      />
    </box>
  )
}

// ─── Brightness Slider ──────────────────────────────────────
function BrightnessSlider() {
  return (
    <box>
      <button tooltipText={createBinding(Brightness, "screen")(
        (v) => `Screen Brightness: ${Math.floor(v * 100)}%`,
      )}>
        <label label={String.fromCodePoint(0xF0599)} />
      </button>
      <slider
        hexpand={true}
        value={createBinding(Brightness, "screen")}
        onChangeValue={({ value }) => {
          Brightness.screen = value
          return false
        }}
      />
    </box>
  )
}

// Safe wrapper: prevents a single getter crash from silently killing
// the entire createComputed (gnim doesn't recover from compute errors).
// Also yields the main loop before each access to process pending
// D-Bus worker callbacks — prevents stale proxy blocking after resume.
function safe<T>(fn: () => T, fallback: T): T {
  try {
    // Process any pending D-Bus worker responses before accessing Astal proxies.
    // Without this, a stale proxy triggers a blocking sync D-Bus call that
    // freezes the entire main loop (S-state, futex_wait).
    GLib.main_context_default().iteration(false)
    return fn()
  } catch (_) { return fallback }
}

// ─── Network Toggle ─────────────────────────────────────────

function NetworkToggle() {
  const network = AstalNetwork.get_default()
  let menuBox: Gtk.Box | null = null
  let parentBox: Gtk.Box | null = null

  const wifiLabel = createComputed(() => safe(() => {
    const enabled = createBinding(network, "wifi", "enabled")()
    if (!enabled) return "Disabled"
    const state = createBinding(network, "wifi", "state")()
    if (state >= 40 && state < 100) return "Connecting…"
    if (state === 100) {
      const ap = createBinding(network, "wifi", "active-access-point")()
      if (!ap) return "Connected"
      const ssid = createBinding(ap, "ssid")()
      return ssid || "Connected"
    }
    return "Not Connected"
  }, "Not Connected"))

  const wifiClass = createComputed(() => safe(() => {
    const enabled = createBinding(network, "wifi", "enabled")()
    if (!enabled) return "toggle-button disabled"
    const state = createBinding(network, "wifi", "state")()
    if (state >= 40 && state < 100) return "toggle-button connecting"
    return "toggle-button"
  }, "toggle-button"))

  return (
    <box
      $={(self) => { parentBox = self }}
      orientation={Gtk.Orientation.VERTICAL}
    >
      <button
        class={wifiClass}
        onClicked={() => {
          if (network.wifi) network.wifi.enabled = !network.wifi.enabled
        }}
        $={(self) => {
          const gesture = new Gtk.GestureClick()
          gesture.set_button(3)
          gesture.connect("pressed", () => {
            if (!menuBox || !parentBox) return
            if (menuBox.visible) {
              parentBox.remove(menuBox)
              menuBox.visible = false
              forceResize()
            } else {
              parentBox.append(menuBox)
              menuBox.visible = true
              forceResize()
            }
          })
          self.add_controller(gesture)
        }}
      >
        <box spacing={8}>
          <label label={createBinding(network, "wifi", "enabled")((e) =>
            e ? String.fromCodePoint(0xF05A9) : String.fromCodePoint(0xF05AA)
          )} />
          <label
            hexpand={true}
            xalign={0}
            maxWidthChars={14}
            ellipsize={Pango.EllipsizeMode.END}
            label={wifiLabel}
          />
        </box>
      </button>
      <box
        $={(self) => {
          menuBox = self
          timeout(1, () => {
            menuBox.visible = false
            const p = menuBox.get_parent()
            if (p && p !== menuBox) p.remove(menuBox)
          })
        }}
        class="menu"
        orientation={Gtk.Orientation.VERTICAL}
      >
        <For each={createBinding(network, "wifi")((w) => w?.accessPoints || [])}>
          {(ap) => (
            <button
              onClicked={() =>
                execAsync(`nmcli device wifi connect ${ap.bssid}`).catch(
                  console.error,
                )
              }
            >
              <box>
                <label label={String.fromCodePoint(0xF05A9)} /> {/* wifi */}
                <label label={ap.ssid || ""} hexpand={true} xalign={0} />
              </box>
            </button>
          )}
        </For>
      </box>
    </box>
  )
}

// ─── Bluetooth Toggle ───────────────────────────────────────

function BluetoothToggle() {
  const bt = AstalBluetooth.get_default()
  const [connectingVer, setConnectingVer] = createState(0)
  let menuBox: Gtk.Box | null = null
  let parentBox: Gtk.Box | null = null

  // Subscribe to per-device connecting changes (bt.devices doesn't fire)
  // Track signal IDs to disconnect before reconnecting — prevents handler accumulation
  let deviceSigIds = new WeakMap<any, number>()
  let watchTimer: any = null
  let debounceConnecting: any = null
  function watchConnecting() {
    // Debounce: BlueZ fires rapid notify::devices during connection — batch them
    if (watchTimer) { watchTimer.cancel(); watchTimer = null }
    watchTimer = timeout(50, () => {
      watchTimer = null
      bt.devices.forEach((d: any) => {
        const oldId = deviceSigIds.get(d)
        if (oldId !== undefined) d.disconnect(oldId)
        const id = d.connect("notify::connecting", () => {
          if (debounceConnecting) { debounceConnecting.cancel() }
          debounceConnecting = timeout(50, () => {
            setConnectingVer((v: number) => v + 1)
          })
        })
        deviceSigIds.set(d, id)
      })
    })
  }
  watchConnecting()
  const devicesChangedId = bt.connect("notify::devices", watchConnecting)
  onCleanup(() => {
    bt.disconnect(devicesChangedId)
    bt.devices.forEach((d: any) => {
      const id = deviceSigIds.get(d)
      if (id !== undefined) d.disconnect(id)
    })
  })

  const btLabel = createComputed(() => safe(() => {
    connectingVer()
    if (!createBinding(bt, "is-powered")()) return "Disabled"
    const hasConnected = createBinding(bt, "is-connected")()
    const devices = createBinding(bt, "devices")()
    if (hasConnected) {
      const connected = devices.filter((d: any) => d.connected)
      if (connected.length === 1) return connected[0].alias || connected[0].name
      return `${connected.length} Connected`
    }
    const connecting = devices.filter((d: any) => d.connecting)
    if (connecting.length > 0) return "Connecting…"
    return "Not Connected"
  }, "Not Connected"))

  return (
    <box
      $={(self) => { parentBox = self }}
      orientation={Gtk.Orientation.VERTICAL}
    >
      <button class={createBinding(bt, "is-powered")((p) =>
          p ? "toggle-button" : "toggle-button disabled"
        )} onClicked={() => {
          if (bt.adapter) bt.adapter.powered = !bt.adapter.powered
        }} $={(self) => {
          const gesture = new Gtk.GestureClick()
          gesture.set_button(3)
          gesture.connect("pressed", () => {
            if (!menuBox || !parentBox) return
            if (menuBox.visible) {
              parentBox.remove(menuBox)
              menuBox.visible = false
              forceResize()
            } else {
              parentBox.append(menuBox)
              menuBox.visible = true
              forceResize()
            }
          })
          self.add_controller(gesture)
        }}>
        <box spacing={8}>
          <label label={createBinding(bt, "is-powered")((p) =>
            p ? String.fromCodePoint(0xF00AF) : String.fromCodePoint(0xF00B2)
          )} />
          <label
            hexpand={true}
            xalign={0}
            maxWidthChars={14}
            ellipsize={Pango.EllipsizeMode.END}
            label={btLabel}
          />
        </box>
      </button>
      <box
        $={(self) => {
          menuBox = self
          timeout(1, () => {
            menuBox.visible = false
            const p = menuBox.get_parent()
            if (p && p !== menuBox) p.remove(menuBox)
          })
        }}
        class="menu"
        orientation={Gtk.Orientation.VERTICAL}
      >
        <For each={createBinding(bt, "devices")}>
          {(device) => (
            <button
              onClicked={() => {
                if (device.connected) device.disconnect_device(() => {})
                else device.connect_device(() => {})
              }}
            >
              <box>
                <label label={String.fromCodePoint(0xF00AF)} /> {/* bluetooth */}
                <label label={device.name} hexpand={true} xalign={0} />
              </box>
            </button>
          )}
        </For>
      </box>
    </box>
  )
}

// ─── Main Control Center ────────────────────────────────────
export default function ControlCenter() {
  let win: Astal.Window
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      $={(self) => {
        win = self
        const ctrl = new Gtk.EventControllerKey()
        ctrl.connect("key-pressed", (_ctrl, keyval) => {
          if (keyval === Gdk.KEY_Escape) toggle()
        })
        self.add_controller(ctrl)
      }}
      visible={false}
      name="control-center"
      namespace="control-center"
      class="ControlCenter"
      anchor={TOP | RIGHT}
      marginRight={8}
      marginTop={4}
      application={app}
      keymode={Astal.Keymode.ON_DEMAND}
    >
      <box class="controlcenter" orientation={Gtk.Orientation.VERTICAL}>
        <Header />
        <box class="sliders-box" orientation={Gtk.Orientation.VERTICAL}>
          <VolumeSlider />
          <BrightnessSlider />
        </box>
        <box class="toggles-row" homogeneous={true} spacing={8}>
          <NetworkToggle />
          <BluetoothToggle />
        </box>
      </box>
    </window>
  )
}
