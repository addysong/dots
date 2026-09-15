local colors = require("utils/colors")

require("hyprland/animations")
-- require("hyprland/env") -- migrated to ~/.config/uwsm/env and env-hyprland for uwsm session
require("hyprland/input")
require("hyprland/keybinds")
require("hyprland/monitors")
require("hyprland/startup")

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 7,

    border_size = 2,

    col = {
      active_border = { colors = { colors.sky, colors.sapphire }, angle = 90 },
      inactive_border = colors.shadow,
    },

    resize_on_border = false,

    allow_tearing = false,

    no_focus_fallback = true,

    layout = "scrolling",
  },

  decoration = {
    rounding = 2,
    rounding_power = 4.0,

    active_opacity = 1.0,
    inactive_opacity = 1.0,

    dim_special = 0.5,

    shadow = {
      enabled = true,
      range = 4,
      render_power = 4,
      color = colors.shadow,
    },

    blur = {
      enabled = true,
      size = 4,
      passes = 1,

      new_optimizations = true,
      xray = false,
      input_methods = true,

      vibrancy = 0.1696,
    },
  },

  xwayland = {
    force_zero_scaling = true,
  },

  master = {
    mfact = 0.5,
  },

  scrolling = {
    follow_min_visible = 1.0,
  },

  misc = {
    enable_anr_dialog = false,
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    allow_session_lock_restore = true,
  },

  binds = {
    workspace_back_and_forth = false,
    hide_special_on_workspace_change = true,
    focus_preferred_method = 1,
    window_direction_monitor_fallback = true,
  },

  cursor = {
    hotspot_padding = 1,
    inactive_timeout = 3,
    hide_on_key_press = false,
  },
})

-- Layer rules
hl.layer_rule({
  name = "blur-waybar",
  match = { namespace = "waybar" },
  blur = true,
})
hl.layer_rule({
  name = "blur-rofi",
  match = { namespace = "rofi" },
  blur = true,
})

-- Config overrides for special workspace
hl.workspace_rule({
  workspace = "s[true]",
  gaps_in = 9,
  gaps_out = 32,
})

hl.window_rule({
  name = "spotify-window-float",
  match = { class = "spotify" },
  float = true,
  size = "500 400",
})

hl.window_rule({
  -- Ignore maximize requests from all apps. You'll probably like this.
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  -- Put file chooser in float
  name = "floating-file-chooser",
  match = { title = "termfilechooser" },
  float = true,
  size = "1200 800",
  opacity = 0.95,
})

hl.window_rule({
  -- Fix some dragging issues with XWayland
  name = "fix-xwayland-drags",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

hl.window_rule({
  name = "kitty-scroll-sensitivity",
  match = { class = "^kitty$" },

  scroll_touchpad = 1.5,
  scroll_mouse = 1.8,
})

-- Hyprland-run windowrule
hl.window_rule({
  name = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move = "20 monitor_h-120",
  float = true,
})
