// Custom brightness service — reads sysfs directly, no process spawns in hot path
import GObject from "gi://GObject"
import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio"
import { execAsync } from "ags/process"
import { monitorFile } from "ags/file"

function readSysfs(path: string): string {
  const [ok, bytes] = GLib.file_get_contents(path)
  return ok ? new TextDecoder().decode(bytes).trim() : ""
}

class BrightnessService extends GObject.Object {
  static #instance: BrightnessService | null = null

  static get_default() {
    if (!this.#instance)
      this.#instance = new BrightnessService()
    return this.#instance
  }

  #iface = ""
  #max = 0
  #screen = 0
  #setting = false

  constructor() {
    super()
    // Enumerate /sys/class/backlight to find the interface name — no shell spawn
    const dir = Gio.File.new_for_path("/sys/class/backlight")
    const en = dir.enumerate_children("standard::name", Gio.FileQueryInfoFlags.NONE, null)
    const info = en.next_file(null)
    this.#iface = info ? info.get_name() : ""
    en.close(null)

    this.#max = Number(readSysfs(`/sys/class/backlight/${this.#iface}/max_brightness`))
    const path = `/sys/class/backlight/${this.#iface}/brightness`
    monitorFile(path, () => this.#onChange())
    this.#onChange()
  }

  get screen() { return this.#screen }

  set screen(percent: number) {
    if (typeof percent !== "number" || isNaN(percent)) return
    percent = Math.max(0, Math.min(1, percent))
    this.#setting = true
    this.#screen = percent
    this.notify("screen")
    execAsync(`brightnessctl s ${Math.round(percent * 100)}% -q`).catch(console.error)
  }

  #onChange() {
    if (this.#setting) { this.#setting = false; return }
    // Direct sysfs read — instant kernel virtual-file access, no process fork
    const val = Number(readSysfs(`/sys/class/backlight/${this.#iface}/brightness`)) / this.#max
    if (Math.abs(val - this.#screen) > 0.01) {
      this.#screen = val
      this.notify("screen")
    }
  }
}

GObject.registerClass(
  {
    GTypeName: "BrightnessService",
    Properties: {
      screen: GObject.ParamSpec.double("screen", "", "", GObject.ParamFlags.READWRITE, 0, 1, 0),
    },
  },
  BrightnessService,
)

export default new BrightnessService()
