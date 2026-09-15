local apps = require("utils/apps")

local scripts = "~/.config/hypr/scripts"
local lock = scripts .. "/lock.sh"

local mainMod = "ALT"
local function mod(key)
  return mainMod .. " + " .. key
end
local function mod_shift(key)
  return mainMod .. " + SHIFT + " .. key
end

-- Lock and exit
hl.bind(mod("escape"), hl.dsp.exec_cmd(lock))
hl.bind(mod_shift("escape"), hl.dsp.exec_cmd("uwsm stop"))

-- Color picker
hl.bind(mod("Y"), hl.dsp.exec_cmd("hyprpicker -alnf hex"))

-- Screenshots
hl.bind(mod("P"), hl.dsp.exec_cmd(apps.screenshot))
hl.bind(mod_shift("P"), hl.dsp.exec_cmd("hyprshot -m window"))

-- Kill current window
hl.bind(mod("Q"), hl.dsp.window.close())

-- Run terminal
hl.bind(mod("T"), hl.dsp.exec_cmd(apps.terminal))
hl.bind(mod("B"), hl.dsp.exec_cmd(apps.browser))
hl.bind(mod("N"), hl.dsp.exec_cmd(apps.notes))

-- TODO: Force a max size for the floating window
hl.bind(mod("F"), function()
  hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  hl.dispatch(hl.dsp.window.center())
end)
-- TODO: update rofi here
hl.bind(mod("R"), hl.dsp.exec_cmd(apps.menu.desktop))
hl.bind(mod_shift("R"), hl.dsp.exec_cmd(apps.menu.run))
hl.bind(mod("C"), hl.dsp.exec_cmd(apps.menu.calc))
hl.bind(mod("E"), hl.dsp.exec_cmd(apps.menu.emoji))
hl.bind(mod("U"), hl.dsp.exec_cmd(apps.menu.unicode))

-- Change drawing tablet display
local tablet_device = "wacom-one-by-wacom-s-pen"
local tablet_default_output = "eDP-1"
local tablet_output = tablet_default_output

local function monitor_index(monitors, name)
  for i, m in ipairs(monitors) do
    if m.name == name then
      return i
    end
  end
  return nil
end

-- Switch table display
hl.bind(mod("D"), function()
  local monitors = hl.get_monitors()
  if #monitors == 0 then
    return
  end

  local index = monitor_index(monitors, tablet_output) or monitor_index(monitors, tablet_default_output) or 1

  tablet_output = monitors[(index % #monitors) + 1].name
  hl.device({ name = tablet_device, output = tablet_output })
  hl.exec_cmd("notify-send --urgency=low --icon=input-tablet 'Tablet output changed to " .. tablet_output .. "'")
end)

-- Toggle touchpad
local touchpad_device = "snsl002d:00-2c2f:002d-touchpad"
local touchpad_enabled = true

hl.bind(mod("A"), function()
  touchpad_enabled = not touchpad_enabled
  hl.device({ name = touchpad_device, enabled = touchpad_enabled })
  hl.exec_cmd(
    "notify-send --urgency=low --icon=input-touchpad 'Touchpad "
      .. (touchpad_enabled and "enabled" or "disabled")
      .. "'"
  )
end)

-- Toggle key repeat for game compatibility
local repeat_rate = nil
hl.bind(mod("G"), function()
  local current_rate = hl.get_config("input.repeat_rate")
  local delay = hl.get_config("input.repeat_delay")
  if current_rate > 0 then
    repeat_rate = current_rate
    hl.config({ input = { repeat_rate = 0 } })
    hl.exec_cmd("notify-send --urgency=low --icon=input-keyboard 'Disabling key repeat'")
  else
    hl.config({ input = { repeat_rate = repeat_rate } })
    hl.exec_cmd("notify-send --urgency=low --icon=input-keyboard 'Enabling key repeat'")
  end
end)

-- Move focus
hl.bind(mod("H"), hl.dsp.focus({ direction = "l" }))
hl.bind(mod("J"), hl.dsp.focus({ direction = "d" }))
hl.bind(mod("K"), hl.dsp.focus({ direction = "u" }))
hl.bind(mod("L"), hl.dsp.focus({ direction = "r" }))

-- Swap windows
hl.bind(mod_shift("H"), hl.dsp.window.swap({ direction = "l" }))
hl.bind(mod_shift("J"), hl.dsp.window.swap({ direction = "d" }))
hl.bind(mod_shift("K"), hl.dsp.window.swap({ direction = "u" }))
hl.bind(mod_shift("L"), hl.dsp.window.swap({ direction = "r" }))

-- Switch workspaces
for i = 1, 9 do
  hl.bind(mod(i), hl.dsp.focus({ workspace = i, on_current_monitor = true }))
end

-- Move active window to a workspace
for i = 1, 9 do
  hl.bind(mod_shift(i), hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Move between displays
hl.bind(mod("tab"), hl.dsp.focus({ monitor = "+1" }))
hl.bind(mod_shift("tab"), hl.dsp.focus({ monitor = "-1" }))

-- Resize columns on scrolling layout
hl.bind(mod("comma"), hl.dsp.layout("colresize -conf"))
hl.bind(mod("period"), hl.dsp.layout("colresize +conf"))

-- Special workspaces
local function toggle_window_special()
  local win = hl.get_active_window()
  if not win or not win.workspace then
    return
  end
  local target = win.workspace.special and "+0" or "special"
  hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false }))
end

hl.bind(mod("S"), hl.dsp.workspace.toggle_special())
hl.bind(mod("M"), toggle_window_special)

-- Move/resize windows using mouse
hl.bind(mod("mouse:272"), hl.dsp.window.drag(), { mouse = true })
hl.bind(mod("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioLowerVolume",
  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioMute",
  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioMicMute",
  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
