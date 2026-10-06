import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs

RowLayout {
  id: root
  spacing: Config.workspaceSpacing

  readonly property bool anySpecialOpen: Hyprland.monitors.values.some(monitor => {
    const special = monitor.lastIpcObject.specialWorkspace;
    return special && special.name !== "";
  })

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "activespecialv2")
        Hyprland.refreshMonitors();
    }
  }

  readonly property color activeColor: Config.blue
  readonly property color inactiveColor: Config.text2
  readonly property color emptyColor: Config.bg3
  readonly property color specialColor: Config.purple

  Repeater {
    model: Hyprland.workspaces

    Item {
      readonly property bool empty: modelData.toplevels.values.length === 0
      implicitWidth: Config.workspaceWidth
      implicitHeight: Config.workspaceHeight

      MultiEffect {
        anchors.fill: workspace
        source: workspace
        shadowEnabled: true
        shadowColor: Config.bg
        shadowBlur: 0.6
      }

      Rectangle {
        id: workspace
        readonly property bool sp: modelData.name.startsWith("special")
        readonly property bool specialOpen: sp && root.anySpecialOpen
        anchors.fill: parent
        radius: Config.workspaceRadius
        color: {
          if (workspace.specialOpen)
            return root.specialColor;
          if (modelData.focused)
            return root.activeColor;
          return Qt.alpha(Config.bg, 0.2);
        }
        border.color: {
          if (workspace.sp)
            return root.specialColor;
          if (modelData.active)
            return root.activeColor;
          if (empty)
            return root.emptyColor;
          return root.inactiveColor;
        }
        border.width: Config.workspaceBorderWidth

        Text {
          anchors.centerIn: parent
          font: Config.mainFont
          color: {
            if (workspace.specialOpen)
              return Config.bg;
            if (workspace.sp)
              return root.specialColor;
            if (modelData.focused)
              return Config.bg;
            if (modelData.active)
              return root.activeColor;
            if (empty)
              return root.emptyColor;
            return root.inactiveColor;
          }

          text: workspace.sp ? "•ᵕ•" : modelData.name
        }
      }
    }
  }
}
