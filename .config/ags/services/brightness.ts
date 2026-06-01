// Custom brightness service using brightnessctl
import GObject from "gi://GObject"
import { exec, execAsync } from "ags/process"
import { monitorFile } from "ags/file"

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
    this.#iface = exec("sh -c 'ls -w1 /sys/class/backlight | head -1'")
    this.#max = Number(exec("brightnessctl max"))
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
    execAsync(
      `brightnessctl s ${Math.round(percent * 100)}% -q`,
    ).catch(console.error)
  }

  #onChange() {
    if (this.#setting) { this.#setting = false; return }
    const val = Number(exec("brightnessctl get")) / this.#max
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
