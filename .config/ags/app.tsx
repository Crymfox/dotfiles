import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { For, This, createBinding } from "ags"
import style from "./style.css"
import Bar from "./bar"
import ControlCenter from "./control-center"
import MediaWindow from "./media-window"
import Calendar from "./calendar"

app.start({
  css: style,
  gtkTheme: "Adwaita",
  main() {
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
