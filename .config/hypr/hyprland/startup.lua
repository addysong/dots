hl.on("hyprland.start", function()
  -- All startup apps launched as uwsm-scoped units (plain `uwsm app --` route).
  hl.exec_cmd("uwsm app -- kanata -c ~/.config/kanata.kbd")
  -- Glyphcache workaround for clock colon glyph bug
  hl.exec_cmd("uwsm app -a qs -- env QML_USE_GLYPHCACHE_WORKAROUND=1 qs -c midnight-blue")
  hl.exec_cmd("uwsm app -- hyprpaper")
  hl.exec_cmd("uwsm app -- hypridle")
  hl.exec_cmd("uwsm app -- fcitx5")

  hl.exec_cmd("uwsm app -- ~/scripts/battery-monitor.sh")

  hl.exec_cmd("uwsm app -- ~/.config/hypr/scripts/random-wall.sh")
end)
