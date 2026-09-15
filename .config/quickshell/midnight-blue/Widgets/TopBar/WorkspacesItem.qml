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

  readonly property var workspaceModel: {
    const current = Hyprland.workspaces.values;
    const result = [];

    for (let id = 1; id <= Config.numWorkspaces; id++) {
      const workspace = current.find(candidate => candidate.id === id);
      result.push({ id, workspace: workspace ?? null });
    }

    // Keep existing special, named, and out-of-range workspaces visible.
    for (const workspace of current) {
      if (workspace.id < 1 || workspace.id > Config.numWorkspaces)
        result.push({ id: workspace.id, workspace });
    }

    // Restore numeric ordering after merging pinned and existing workspaces.
    // This keeps negative-ID special workspaces to the left.
    return result.sort((a, b) => a.id - b.id);
  }

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
    model: root.workspaceModel

    Item {
      readonly property var workspaceData: modelData.workspace
      readonly property bool empty: workspaceData === null || workspaceData.toplevels.values.length === 0
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
        readonly property bool sp: workspaceData !== null && workspaceData.name.startsWith("special")
        readonly property bool specialOpen: sp && root.anySpecialOpen
        anchors.fill: parent
        radius: Config.workspaceRadius
        color: {
          if (workspace.specialOpen)
            return root.specialColor;
          if (workspaceData !== null && workspaceData.focused)
            return root.activeColor;
          return Qt.alpha(Config.bg, 0.2);
        }
        border.color: {
          if (workspace.sp)
            return root.specialColor;
          if (workspaceData !== null && workspaceData.active)
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
            if (workspaceData !== null && workspaceData.focused)
              return Config.bg;
            if (workspaceData !== null && workspaceData.active)
              return root.activeColor;
            if (empty)
              return root.emptyColor;
            return root.inactiveColor;
          }

          text: workspace.sp ? "•ᵕ•" : workspaceData === null ? String(modelData.id) : workspaceData.name
        }
      }
    }
  }
}
