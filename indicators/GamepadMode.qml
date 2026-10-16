import QtQuick
import qs.Commons
import qs.Ui
import "../Model.js" as Model

// A single hardware-backed toggle. "active" also keeps unavailable states
// visible in the active indicator block; gamepadEnabled is the actual ON state.
BarIndicator {
  id: root

  readonly property var service: bar && bar.shell
    ? bar.shell.serviceFor("io.github.ol4vr.keychron-profiles") : null
  readonly property var snapshot: service ? service.snapshot : null
  readonly property bool busy: service ? service.busy === true : false
  readonly property bool hardwareReady: Model.canSwitch(snapshot)
  readonly property bool gamepadEnabled: hardwareReady && snapshot.activeIndex === 2
  readonly property bool unavailable: !hardwareReady
  readonly property string statusTooltip: root.tooltipForState()

  function tooltipForState() {
    if (root.busy)
      return "Gamepad Mode · Waiting for hardware confirmation"
    if (root.hardwareReady)
      return root.gamepadEnabled
        ? "Disable Gamepad Mode · K10 HE"
        : "Enable Gamepad Mode · K10 HE"
    if (root.snapshot && root.snapshot.state === "ready" && root.snapshot.activeIndex === 1)
      return "Gamepad Mode unavailable · Profile 2 active"
    return "Gamepad Mode unavailable · " + Model.stateLabel(root.snapshot)
  }

  // Unavailable is intentionally neither the dim OFF state nor an actionable
  // ON state: it stays visible in the urgent color and interaction is disabled.
  active: root.unavailable || root.gamepadEnabled
  activeText: "󰊗"
  inactiveText: "󰊗"
  activeTooltipText: root.statusTooltip
  inactiveTooltipText: root.statusTooltip
  interactive: belongsInBlock && root.hardwareReady && !root.busy
    && (effectiveActive || indicatorBlock === "inactive" || inactiveRevealed)
  dimmed: root.hardwareReady && !root.gamepadEnabled
  foreground: root.unavailable
    ? Color.urgent
    : (root.gamepadEnabled && Color.shellValues["bar.accent-icons"] === "true"
      ? Color.pick("bar.icon-accent", Color.accent)
      : (bar ? bar.barForeground : Color.foreground))

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() {
      if (root.service) root.service.refresh()
    }
  }

  onPressed: function() {
    if (!root.hardwareReady || root.busy || !root.service) return
    root.service.selectProfile(root.gamepadEnabled ? "default" : "gamepad")
  }
}
