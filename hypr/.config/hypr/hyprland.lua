-- Hyprland v0.55+ Native Lua Configuration
-- Located in ~/dotfiles/.config/hypr/hyprland.lua
-- Fully replicated from v0.42.0 conf files

-- ==========================================
-- Environment Variables
-- Only vars documented in the Hyprland wiki.
-- Electron/Chromium flags moved to ~/.config/electron-flags.conf.
-- ==========================================
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("HYPRCURSOR_THEME", "Geared-Copper")
hl.env("HYPRCURSOR_SIZE", "64")

-- NOTE: NVIDIA env vars removed - they conflict with Chromium's Wayland backend
-- on this dual-GPU (Intel + NVIDIA) system. GBM_BACKEND=nvidia-drm in particular
-- breaks Wayland buffer sharing on the Intel-driven display.
-- hl.env("WLR_NO_HARDWARE_CURSORS", "1")
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- Force GTK4 to use OpenGL renderer — Vulkan (vkGetFenceStatus) crashes
-- on Intel+NVIDIA dual-GPU when power state changes (e.g. charger plug).
hl.env("GSK_RENDERER", "opengl")

-- ==========================================
-- Monitors
-- ==========================================
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@60.00",
	position = "0x0",
	scale = 1.2,
})

hl.monitor({
	output = "HDMI-A-2",
	mode = "1440x900@60.07",
	position = "-1800x-440",
	scale = 0.8,
})

-- Fallback for unknown monitors
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

-- ==========================================
-- Core Configuration
-- ==========================================
hl.config({
	input = {
		kb_layout = "fr",
		numlock_by_default = true,
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
		},
	},
	general = {
		layout = "dwindle",
		gaps_in = 4,
		gaps_out = 4,
		border_size = 2,
		["col.active_border"] = "rgba(8B72E0ff)",
	},
	decoration = {
		rounding = 4,
		dim_inactive = false,
		dim_strength = 0.1,
		dim_special = 0.4,
		dim_around = 0.4,
		inactive_opacity = 1.0,
		-- drop_shadow = false, (deprecated)
		-- shadow_range = 10, (deprecated)
		-- shadow_render_power = 10, (deprecated)
		blur = {
			enabled = true,
			size = 2,
			passes = 4,
			new_optimizations = true,
			xray = false,
			brightness = 0.7,
		},
	},
	misc = {
		-- vfr = true, (deprecated)
		mouse_move_focuses_monitor = true,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
	},
	dwindle = {
		-- pseudotile = true, (deprecated)
		force_split = 2,
		preserve_split = true,
		smart_split = false,
		smart_resizing = true,
		permanent_direction_override = false,
		special_scale_factor = 0.8,
		split_width_multiplier = 1.0,
		-- no_gaps_when_only = 0, (deprecated)
		use_active_for_splits = true,
		default_split_ratio = 1.0,
	},
	xwayland = {
		force_zero_scaling = true,
	},
})

-- Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- ==========================================
-- Animations
-- ==========================================
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("bezier2", { type = "bezier", points = { { 0.5, 0.1 }, { 0.5, 0.9 } } })
hl.curve("borderCurve", { type = "bezier", points = { { 0.2, 0.3 }, { 0.8, 0.7 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "bezier2" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 10, bezier = "borderCurve", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "myBezier", style = "slidevert" })

-- ==========================================
-- Autostart
-- ==========================================
hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/xdg-portal-hyprland")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("ags run --log-file /tmp/ags.log")
	hl.exec_cmd("mako")
	hl.exec_cmd("nohup wl-paste --type text --watch cliphist store > /dev/null 2>&1 &")
	hl.exec_cmd("nohup wl-paste --type image --watch cliphist store > /dev/null 2>&1 &")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("hyprctl notify -1 3000 'rgb(7aa2f7)' 'Startup Finished :)'")
end)

-- ==========================================
-- Window & Layer Rules
-- ==========================================
-- Layer Rules
-- hl.layer_rule({ name = "waybar_blur"...
-- hl.layer_rule({ name = "waybar_ignore", match = { namespace = "waybar" }, ignorezero = true }) -- deprecated
-- hl.layer_rule({ name = "thunar_blur"...
-- hl.layer_rule({ name = "gtk_blur"...

-- Float Rules
hl.window_rule({ name = "float_pavu", match = { class = "pavucontrol" }, float = true })
hl.window_rule({ name = "float_blue", match = { class = "blueman-manager" }, float = true })
hl.window_rule({ name = "float_nm", match = { class = "nm-connection-editor" }, float = true })
hl.window_rule({ name = "float_xdg_gtk", match = { class = "xdg-desktop-portal-gtk" }, float = true })
hl.window_rule({ name = "float_xdg_kde", match = { class = "xdg-desktop-portal-kde" }, float = true })
hl.window_rule({ name = "float_xdg_hypr", match = { class = "xdg-desktop-portal-hyprland" }, float = true })

-- Picture-in-Picture
hl.window_rule({
	name = "pip_rule",
	match = { title = "Picture in picture" },
	float = true,
	size = "960 540",
	move = "25% 25%",
})

-- Opacity Rules
-- hl.window_rule({ name = "thunar_op", match = { class = "thunar" }, opacity_active = 1.0, opacity_inactive = 0.85 }) -- deprecated
-- hl.window_rule({ name = "wezterm_op", match = { class = "org.wezfurlong.wezterm" }, opacity_active = 0.97, opacity_inactive = 0.9 }) -- deprecated
-- hl.window_rule({ name = "float_op", match = { float = true }, opacity_active = 0.90, opacity_inactive = 0.90 }) -- deprecated

-- Blur Rules (from previous config)
local blurred_apps = { "kitty", "rofi", "nemo", "foot" }
for _, app in ipairs(blurred_apps) do
	-- hl.window_rule({ name = "blur_" .. app, match = { class = app }, blur = true }) -- deprecated
end
-- hl.window_rule({ name = "noblur_ff", match = { class = "firefox" }, blur = false }) -- deprecated

-- Submap border rule (matches all windows via regex, disabled by default)
local wm_border_rule = hl.window_rule({
	name = "submap_border",
	match = { title = ".*" },
	border_color = { colors = { "rgba(FF6B6Bff)", "rgba(FFD93Dff)" }, angle = 45 },
})
wm_border_rule:set_enabled(false)

-- Submap rules
hl.window_rule({ name = "submap_center", match = { title = "submap" }, float = true, center = true })

-- XWayland workaround for Chromium (Arch package lacks Wayland backend)
-- Opens maximized so it fills the monitor correctly with force_zero_scaling
-- hl.window_rule({ name = "chromium_max", match = { class = "chromium" }, maximize = true })
-- hl.window_rule({ name = "chromium_max2", match = { class = "Chromium" }, maximize = true })

-- ==========================================
-- Keybindings
-- ==========================================
local mainMod = "SUPER"

-- Applications
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("~/scripts/launch.sh terminal"))
hl.bind(mainMod .. " + KP_Enter", hl.dsp.exec_cmd("~/scripts/launch.sh terminal"))
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.exec_cmd("~/scripts/launch.sh terminal2"))
hl.bind(mainMod .. " + CTRL + KP_Enter", hl.dsp.exec_cmd("~/scripts/launch.sh terminal2"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/scripts/launch.sh terminal2"))
hl.bind(mainMod .. " + CTRL + T", hl.dsp.exec_cmd("tmux"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("hyprctl dispatch workspace 2 && ~/scripts/launch.sh browser"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("~/scripts/launch.sh filesgui"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("hyprctl dispatch workspace 5 && telegram-desktop"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/scripts/launch.sh rofi"))
hl.bind(mainMod .. " + KP_Add", hl.dsp.exec_cmd("~/scripts/launch.sh rofi"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("~/scripts/launch.sh dmenu"))

-- Utilities & Session
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/scripts/launch.sh clipboard"))
hl.bind("print", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind("CTRL + print", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("SHIFT + print", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + KP_Subtract", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("~/scripts/wlogout.sh"))
hl.bind(mainMod .. " + ALT + Q", hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + escape", hl.dsp.exec_cmd("hyprlock"))

-- Window Manipulation
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + CTRL + F", hl.dsp.exec_cmd("hyprctl dispatch centerwindow"))
hl.bind(mainMod .. " + ALT + TAB", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg swapwithmaster"))
-- Cycle through all windows (tiled + floating) with Alt+Tab
hl.bind("ALT + Tab", function()
	hl.dispatch(hl.dsp.window.cycle_next())
	hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

-- Focus Movement (Vim & Arrows)
local dirs = { h = "l", l = "r", k = "u", j = "d", left = "l", right = "r", up = "u", down = "d" }
local resize_vals = {
	h = { x = -10, y = 0 },
	l = { x = 10, y = 0 },
	k = { x = 0, y = -10 },
	j = { x = 0, y = 10 },
	left = { x = -10, y = 0 },
	right = { x = 10, y = 0 },
	up = { x = 0, y = -10 },
	down = { x = 0, y = 10 },
}
for key, dir in pairs(dirs) do
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = dir }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
	hl.bind(
		mainMod .. " + CTRL + " .. key,
		hl.dsp.window.resize({ x = resize_vals[key].x, y = resize_vals[key].y, relative = true }),
		{ repeating = true }
	)
end

-- Monitor Focus
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprctl dispatch focusmonitor +1"))
hl.bind(mainMod .. " + BracketLeft", hl.dsp.exec_cmd("hyprctl dispatch focusmonitor +1"))
hl.bind(mainMod .. " + BracketRight", hl.dsp.exec_cmd("hyprctl dispatch focusmonitor -1"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:+1"))
hl.bind(mainMod .. " + SHIFT + BracketLeft", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:+1"))
hl.bind(mainMod .. " + SHIFT + BracketRight", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:-1"))
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.exec_cmd("hyprctl dispatch swapactiveworkspaces current +1"))

-- Workspaces (AZERTY Top Row & Numpad)
local azerty_keys = {
	"ampersand",
	"eacute",
	"quotedbl",
	"apostrophe",
	"parenleft",
	"I",
	"O",
	"P",
	"dead_circumflex",
	"dollar",
}
local numpad_keys = {
	"KP_Insert",
	"KP_End",
	"KP_Down",
	"KP_Next",
	"KP_Left",
	"KP_Begin",
	"KP_Right",
	"KP_Home",
	"KP_Up",
	"KP_Prior",
}

for i = 1, 10 do
	local keys = { azerty_keys[i], numpad_keys[i] }
	for _, key in ipairs(keys) do
		-- Switch workspace
		hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
		hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.exec_cmd("hyprctl dispatch workspace " .. i)) -- Active monitor

		-- Move window to workspace
		hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))

		-- Move window silently (follow = false = silent)
		hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
	end
end

-- Scratchpads (Special Workspaces)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + KP_Multiply", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + SHIFT + KP_Multiply", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }))
hl.bind(mainMod .. " + ALT + KP_Multiply", hl.dsp.window.move({ workspace = "special:magic", follow = false }))

hl.bind(mainMod .. " + A", hl.dsp.workspace.toggle_special("secondary"))
hl.bind(mainMod .. " + KP_Divide", hl.dsp.workspace.toggle_special("secondary"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.window.move({ workspace = "special:secondary" }))
hl.bind(mainMod .. " + SHIFT + KP_Divide", hl.dsp.window.move({ workspace = "special:secondary" }))
hl.bind(mainMod .. " + ALT + A", hl.dsp.window.move({ workspace = "special:secondary", follow = false }))
hl.bind(mainMod .. " + ALT + KP_Divide", hl.dsp.window.move({ workspace = "special:secondary", follow = false }))

-- Media Controls
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/scripts/volume.sh inc"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/scripts/volume.sh dec"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/scripts/volume.sh mute"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/scripts/brightness --inc"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/scripts/brightness --dec"), { repeating = true })

-- 60% keyboard volume binds
hl.bind(mainMod .. " + equal", hl.dsp.exec_cmd("~/scripts/volume.sh inc"))
hl.bind(mainMod .. " + minus", hl.dsp.exec_cmd("~/scripts/volume.sh dec"))
hl.bind(mainMod .. " + 0", hl.dsp.exec_cmd("~/scripts/volume.sh mute"))

-- CTRL + volume keys for playback
hl.bind("CTRL + XF86AudioRaiseVolume", hl.dsp.exec_cmd("playerctl next"))
hl.bind("CTRL + XF86AudioLowerVolume", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("CTRL + XF86AudioMute", hl.dsp.exec_cmd("playerctl play-pause"))

-- Mouse binds
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ==========================================
-- WindowMode Submap: press SUPER+W to enter,
-- then use plain keys for window ops.
-- Border changes to warm gradient while active.
-- Esc/Enter to exit.
-- ==========================================
hl.bind(mainMod .. " + W", function()
	wm_border_rule:set_enabled(true)
	hl.dispatch(hl.dsp.submap("WindowMode"))
end)

hl.define_submap("WindowMode", function()
	-- Focus, move, resize with arrow keys / vim keys
	local wm_keys = {
		h = { dir = "l", resize = { x = -10, y = 0 } },
		l = { dir = "r", resize = { x = 10, y = 0 } },
		k = { dir = "u", resize = { x = 0, y = -10 } },
		j = { dir = "d", resize = { x = 0, y = 10 } },
		left = { dir = "l", resize = { x = -10, y = 0 } },
		right = { dir = "r", resize = { x = 10, y = 0 } },
		up = { dir = "u", resize = { x = 0, y = -10 } },
		down = { dir = "d", resize = { x = 0, y = 10 } },
	}
	for key, spec in pairs(wm_keys) do
		hl.bind(key, hl.dsp.focus({ direction = spec.dir }))
		hl.bind("SHIFT + " .. key, hl.dsp.window.move({ direction = spec.dir }))
		hl.bind(
			"CTRL + " .. key,
			hl.dsp.window.resize({ x = spec.resize.x, y = spec.resize.y, relative = true }),
			{ repeating = true }
		)
	end

	-- Custom shortcuts while in submap
	hl.bind("q", hl.dsp.window.close())
	hl.bind("KP_Subtract", hl.dsp.window.close())
	hl.bind("f", hl.dsp.window.fullscreen())
	hl.bind("SHIFT + f", hl.dsp.window.float({ action = "toggle" }))
	hl.bind("space", hl.dsp.focus({ last = true }))

	-- Mouse binds (no modifiers needed in submap context)
	hl.bind("mouse:272", hl.dsp.window.drag(), { mouse = true })
	hl.bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

	-- Exit submap (restore default border)
	hl.bind("escape", function()
		wm_border_rule:set_enabled(false)
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("return", function()
		wm_border_rule:set_enabled(false)
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("KP_Enter", function()
		wm_border_rule:set_enabled(false)
		hl.dispatch(hl.dsp.submap("reset"))
	end)
end)
