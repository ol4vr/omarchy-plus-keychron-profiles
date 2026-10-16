import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// One process-wide poll owner. Per-monitor widgets consume this shared state.
Item {
  id: root

  readonly property string helperPath: Quickshell.env("HOME")
    + "/.config/omarchy/plugins/io.github.ol4vr.keychron-profiles/keychron-profiles"
  property string serial: ""
  property var snapshot: ({
    schema: 1,
    state: "checking",
    message: "Reading the K10 HE hardware profile.",
    activeIndex: null,
    activeProfile: null
  })
  property string processOutput: ""
  property string processError: ""
  readonly property bool busy: statusProcess.running || actionProcess.running

  function command(arguments) {
    var result = [root.helperPath]
    if (root.serial !== "") result = result.concat(["--serial", root.serial])
    return result.concat(arguments)
  }

  function configureSerial(value) {
    var next = String(value || "").trim()
    if (next === root.serial) return
    root.serial = next
    root.refresh()
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
}
