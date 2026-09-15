import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs

TopBarItem {
  id: root

  readonly property var activeWindow: Hyprland.activeToplevel
  readonly property string appId: {
    if (!activeWindow)
      return "";
    if (activeWindow.wayland && activeWindow.wayland.appId)
      return activeWindow.wayland.appId;

    const ipcData = activeWindow.lastIpcObject;
    return ipcData ? ipcData.class || ipcData.initialClass || "" : "";
  }
  readonly property var desktopEntry: {
    const entries = DesktopEntries.applications.values;
    return appId && entries.length > 0 ? DesktopEntries.heuristicLookup(appId) : null;
  }
  readonly property string appName: desktopEntry ? desktopEntry.name : appId
  readonly property real maximumTextWidth: 400

  text: nameMetrics.elidedText
  visible: appName.length > 0

  TextMetrics {
    id: nameMetrics
    font: Config.mainFont
    text: root.appName
    elide: Text.ElideRight
    elideWidth: root.maximumTextWidth
  }
}
