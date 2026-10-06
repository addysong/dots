return {
  browser = "xdg-open https://",
  menu = {
    desktop = "rofi -show drun -display-drun Apps -drun-match-fields name",
    run = "rofi -show run -display-run Run",
    calc = "rofi -show calc -display-calc Calc",
    emoji = "rofimoji --action copy",
    unicode = "rofimoji --action copy --files all",
  },
  notes = "obsidian",
  screenshot = "hyprshot -m region",
  terminal = "kitty",
}
