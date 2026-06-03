import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { For, This, createBinding } from "ags"
import style from "./style.css"
import Bar from "./bar"
import ControlCenter from "./control-center"
import MediaWindow from "./media-window"
import Calendar from "./calendar"
import { watchResume } from "./services/resume"

app.start({
  css: style,
  gtkTheme: "Adwaita",
  main() {
    // Safety net: restart AGS after suspend/resume to fix stale Astal D-Bus proxies
    watchResume()

    const monitors = createBinding(app, "monitors")

    return (
      <This this={app}>
        {/* <For each={monitors}> */}
        {/*   {(monitor) => <Bar gdkmonitor={monitor} />} */}
        {/* </For> */}
        <Bar gdkmonitor={app.monitors[0]} />
        <ControlCenter />
        <MediaWindow />
        <Calendar />
      </This>
    )
  },
})
