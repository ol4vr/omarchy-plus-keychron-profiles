import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarIndicator {
  id: root

  property bool pttEnabled: false

  active: pttEnabled
  activeText: ""
  inactiveText: ""
  activeTooltipText: "Discord PTT"
  inactiveTooltipText: "Discord PTT"

  function refresh() {
    if (statusProcess.running) return
    statusProcess.command = ["omarchy-plus-discord-ptt", "status"]
    statusProcess.running = true
  }

  onBarChanged: refresh()
  Component.onCompleted: refresh()

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() { root.refresh() }
  }

  Timer {
    id: refreshTimer
    interval: 200
    repeat: false
    onTriggered: root.refresh()
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy-plus/discord-ptt/enabled"
    watchChanges: true
    printErrors: false
    onFileChanged: refreshTimer.restart()
    onLoaded: refreshTimer.restart()
    onLoadFailed: refreshTimer.restart()
  }

  Process {
    id: statusProcess
    onExited: function(exitCode) {
      root.pttEnabled = exitCode === 0
    }
  }

  onPressed: function() {
    if (!root.bar) return
    root.bar.run("omarchy-plus-discord-ptt toggle")
    refreshTimer.restart()
  }
}
