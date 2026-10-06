import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs

RowLayout {
  id: root
  spacing: Config.workspaceSpacing
  visible: columnCount > 0

  property int safetyMs: 500 // Set to 0 to disable.

  property int columnCount: 0
  property int focusedColumn: -1
  property bool queryPending: false

  readonly property var triggerEvents: ["activewindowv2", "movewindow", "movewindowv2", "openwindow", "closewindow", "workspacev2", "focusedmon", "moveworkspacev2", "createworkspacev2", "destroyworkspacev2", "renameworkspace", "changefloatingmode", "togglefloating", "fullscreen", "activelayout", "configreloaded"]

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (root.triggerEvents.indexOf(event.name) !== -1)
        root.scheduleQuery();
    }
  }

  Timer {
    id: coalesceTimer
    interval: 10
    onTriggered: root.query()
  }

  Process {
    id: clientsProc
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
    }
    onRunningChanged: if (!running)
      root.finishQuery()
  }

  Process {
    id: workspaceProc
    command: ["hyprctl", "activeworkspace", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
    }
    onRunningChanged: if (!running)
      root.finishQuery()
  }

  function scheduleQuery() {
    coalesceTimer.stop();
    coalesceTimer.start();
  }

  function query() {
    if (clientsProc.running || workspaceProc.running) {
      queryPending = true;
      return;
    }

    clientsProc.running = true;
    workspaceProc.running = true;
  }

  function finishQuery() {
    if (clientsProc.running || workspaceProc.running)
      return;

    update(clientsProc.stdout.text, workspaceProc.stdout.text);

    if (queryPending) {
      queryPending = false;
      query();
    }
  }

  function update(clientsJson, workspaceJson) {
    let clients;
    let workspace;

    try {
      clients = JSON.parse(clientsJson);
      workspace = JSON.parse(workspaceJson);
    } catch (error) {
      return;
    }

    if (workspace.tiledLayout !== "scrolling") {
      columnCount = 0;
      focusedColumn = -1;
      return;
    }

    const columnXs = new Set();
    let focusedX;

    for (const client of clients) {
      if (client.workspace.id !== workspace.id || client.floating)
        continue;

      const x = client.at[0];
      columnXs.add(x);

      if (client.address === workspace.lastwindow)
        focusedX = x;
    }

    const columns = Array.from(columnXs).sort((a, b) => a - b);
    columnCount = columns.length;
    focusedColumn = focusedX === undefined ? -1 : columns.indexOf(focusedX);
  }

  // Some same-workspace scrolling operations do not emit a Hyprland event.
  Timer {
    interval: root.safetyMs
    repeat: true
    running: root.safetyMs > 0
    onTriggered: root.query()
  }

  Component.onCompleted: query()

  Repeater {
    model: root.columnCount

    Item {
      implicitWidth: 5
      implicitHeight: Config.barHeight

      readonly property bool focused: index === root.focusedColumn

      MultiEffect {
        anchors.fill: blip
        source: blip
        shadowEnabled: true
        shadowColor: Config.bg
        shadowBlur: 0.6
      }

      Rectangle {
        id: blip
        anchors.centerIn: parent
        width: parent.focused ? Config.scrollerLineWidth : Config.scrollerDotSize
        height: parent.focused ? Math.round(Config.scrollerHeight) : Config.scrollerDotSize
        radius: width / 2
        color: parent.focused ? Config.blue : Config.text1
      }
    }
  }
}
