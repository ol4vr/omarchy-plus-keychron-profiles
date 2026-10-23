import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model
import "CopyOnSelectModel.js" as CopyOnSelectModel

// One process-wide poll owner. Per-monitor widgets consume this shared state.
Item {
  id: root

  readonly property string helperPath: Quickshell.env("HOME")
    + "/.config/omarchy/plugins/io.github.ol4vr.keychron-profiles/keychron-profiles"
  readonly property string copyOnSelectReconcilerPath: Quickshell.env("HOME")
    + "/Projects/omarchy-plus/scripts/hugin/reconcile-copy-on-select"
  property var snapshot: ({
    schema: 1,
    state: "checking",
    message: "Reading the connected Keychron HE hardware profile.",
    activeIndex: null,
    activeProfile: null
  })
  property string processOutput: ""
  property string processError: ""
  readonly property bool busy: statusProcess.running || actionProcess.running
  property var copyOnSelectSnapshot: ({
    schema: 1,
    state: "checking",
    enabled: false,
    message: "Reading the Copy on Select state."
  })
  property string copyOnSelectOutput: ""
  property string copyOnSelectError: ""
  property var pendingCopyOnSelectState: null
  readonly property bool copyOnSelectBusy: copyOnSelectStatusProcess.running
    || copyOnSelectActionProcess.running

  function command(arguments) {
    return [root.helperPath].concat(arguments)
  }

  function acceptOutput(raw, fallbackState, fallbackMessage) {
    var parsed = Model.parseStatus(raw)
    root.snapshot = parsed || {
      schema: 1,
      state: fallbackState,
      message: fallbackMessage,
      activeIndex: null,
      activeProfile: null
    }
  }

  function refresh() {
    if (root.busy) return
    root.processOutput = ""
    root.processError = ""
    statusProcess.command = root.command(["status"])
    statusProcess.running = true
  }

  function selectProfile(name) {
    if (root.busy || !Model.canSwitch(root.snapshot)) return
    if (["default", "gamepad"].indexOf(name) === -1) return
    root.processOutput = ""
    root.processError = ""
    actionProcess.command = root.command(["select", name])
    actionProcess.running = true
  }

  function copyOnSelectCommand(action) {
    return [root.copyOnSelectReconcilerPath, action]
  }

  function refreshCopyOnSelect() {
    if (root.copyOnSelectBusy) return
    root.copyOnSelectOutput = ""
    root.copyOnSelectError = ""
    copyOnSelectStatusProcess.command = root.copyOnSelectCommand("check")
    copyOnSelectStatusProcess.running = true
  }

  function setCopyOnSelect(enabled) {
    if (root.copyOnSelectBusy
        || !CopyOnSelectModel.canToggle(root.copyOnSelectSnapshot)) return
    root.pendingCopyOnSelectState = enabled === true
    root.copyOnSelectOutput = ""
    root.copyOnSelectError = ""
    copyOnSelectActionProcess.command = root.copyOnSelectCommand(
      enabled === true ? "feature-on" : "feature-off")
    copyOnSelectActionProcess.running = true
  }

  Process {
    id: statusProcess
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.processOutput = text.trim()
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.processError = text.trim()
    }
    onExited: function(exitCode) {
      root.acceptOutput(
        root.processOutput,
        exitCode === 0 ? "protocol_error" : "io_error",
        root.processError || "The helper returned an invalid status response."
      )
    }
  }

  Process {
    id: copyOnSelectStatusProcess
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.copyOnSelectOutput = text.trim()
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.copyOnSelectError = text.trim()
    }
    onExited: function(exitCode) {
      var parsed = exitCode === 0
        ? CopyOnSelectModel.parseStatus(root.copyOnSelectOutput) : null
      if (!parsed) {
        root.copyOnSelectSnapshot = CopyOnSelectModel.failure(
          "Copy on Select state could not be verified.")
      } else if (root.pendingCopyOnSelectState !== null
                 && parsed.enabled !== root.pendingCopyOnSelectState) {
        root.copyOnSelectSnapshot = CopyOnSelectModel.failure(
          "Copy on Select did not reach the requested state.")
      } else {
        root.copyOnSelectSnapshot = parsed
      }
      root.pendingCopyOnSelectState = null
    }
  }

  Process {
    id: copyOnSelectActionProcess
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.copyOnSelectOutput = text.trim()
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.copyOnSelectError = text.trim()
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.pendingCopyOnSelectState = null
        root.copyOnSelectSnapshot = CopyOnSelectModel.failure(
          "Copy on Select could not be changed.")
        return
      }
      Qt.callLater(root.refreshCopyOnSelect)
    }
  }

  property FileView copyOnSelectConfigWatch: FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy-plus/copy-on-select.json"
    watchChanges: true
    printErrors: false
    onFileChanged: {
      reload()
      Qt.callLater(root.refreshCopyOnSelect)
    }
  }

  Process {
    id: actionProcess
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.processOutput = text.trim()
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.processError = text.trim()
    }
    onExited: function(exitCode) {
      root.acceptOutput(
        root.processOutput,
        exitCode === 0 ? "protocol_error" : "selection_failed",
        root.processError || "The helper returned an invalid selection response."
      )
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: root.refreshCopyOnSelect()
}
