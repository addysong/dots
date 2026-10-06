pragma Singleton
import Quickshell
import QtQuick

Singleton {
  id: root

  // Colors (from Catppuccin Mocha)

  readonly property color red: "#f38ba8"    // red
  readonly property color orange: "#fab387" // peach
  readonly property color yellow: "#f9e2af" // yellow
  readonly property color green: "#a6e3a1"  // green
  readonly property color cyan: "#89dceb"   // sky
  readonly property color blue: "#89b4fa"   // blue
  readonly property color purple: "#cba6f7" // mauve
  readonly property color pink: "#f5c2e7"   // pink

  readonly property color text: "#cdd6f4"  // text
  readonly property color text1: "#bac2de" // subtext1
  readonly property color text2: "#a6adc8" // subtext0
  readonly property color text3: "#7f849c" // overlay1

  readonly property color bg3: "#45475a" // surface1
  readonly property color bg2: "#313244" // surface0
  readonly property color bg1: "#1e1e2e" // base
  readonly property color bg: "#11111b"  // crust

  readonly property color select: "#585b70" // surface2

  // Fonts

  readonly property font mainFont: Qt.font({
    family: "JetBrainsMono Nerd Font Propo",
    pixelSize: 15,
    weight: 300
  })

  readonly property font iconFont: Qt.font({
    family: "Material Symbols Rounded",
    pixelSize: 14,
    weight: 300
  })

  // Bar layout

  // General
  readonly property int barHeight: 20
  readonly property int barSpacing: 12
  readonly property int trayIconSize: 18
  readonly property int fcitxTrayIconSize: 20
  // Workspaces
  readonly property int workspaceWidth: 24
  readonly property int workspaceHeight: 16
  readonly property int workspaceBorderWidth: 1
  readonly property int workspaceRadius: 3
  readonly property int workspaceSpacing: 4
  // Scroller
  readonly property int scrollerHeight: 10
  readonly property int scrollerDotSize: 4
  readonly property int scrollerLineWidth: 3
}
