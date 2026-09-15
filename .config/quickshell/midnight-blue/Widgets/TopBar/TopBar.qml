import Quickshell
import QtQuick
import QtQuick.Layouts
import qs

PanelWindow {
  property var modelData
  screen: modelData

  anchors {
    top: true
    left: true
    right: true
  }
  color: "transparent"
  implicitHeight: Config.barHeight

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop {
        position: 0.0
        color: Qt.alpha(Config.bg, 0.5)
      }
      GradientStop {
        position: 0.6
        color: Qt.alpha(Config.bg, 0.25)
      }
      GradientStop {
        position: 1.0
        color: Qt.alpha(Config.bg, 0.0)
      }
    }
  }

  RowLayout {
    anchors.left: parent.left
    anchors.leftMargin: Config.barSpacing / 2
    anchors.verticalCenter: parent.verticalCenter
    spacing: Config.barSpacing

    WorkspacesItem {}
    ScrollerItem {}
    TrayItem {}
  }

  RowLayout {
    id: center
    anchors.centerIn: parent
    anchors.verticalCenter: parent.verticalCenter
    spacing: Config.barSpacing

    WindowTitleItem {}
  }

  RowLayout {
    anchors.right: parent.right
    anchors.rightMargin: Config.barSpacing / 2
    anchors.verticalCenter: parent.verticalCenter
    spacing: Config.barSpacing

    PowerProfileItem {}
    WifiItem {}
    BatteryItem {}
    BrightnessItem {}
    VolumeItem {}
    ClockItem {}
  }
}
