import QtQuick
import qs.Commons
import qs.Ui
import "../CopyOnSelectModel.js" as CopyOnSelectModel

BarIndicator {
  id: root

  readonly property var service: bar && bar.shell
    ? bar.shell.serviceFor("io.github.ol4vr.keychron-profiles") : null
  readonly property var snapshot: service ? service.copyOnSelectSnapshot : null
  readonly property bool busy: service ? service.copyOnSelectBusy === true : false
  readonly property bool ready: CopyOnSelectModel.canToggle(snapshot)
  readonly property bool featureEnabled: ready && snapshot.enabled === true
  readonly property bool unavailable: !ready

  active: root.unavailable || root.featureEnabled
  activeText: ""
  inactiveText: ""
  activeTooltipText: root.unavailable
    ? "Copy on Select unavailable"
    : (root.busy ? "Copy on Select · Verifying…" : "Disable Copy on Select")
  inactiveTooltipText: root.busy
    ? "Copy on Select · Verifying…" : "Enable Copy on Select"
  interactive: belongsInBlock && root.ready && !root.busy
    && (effectiveActive || indicatorBlock === "inactive" || inactiveRevealed)
  dimmed: root.ready && !root.featureEnabled
  foreground: root.unavailable
    ? Color.urgent
    : (root.featureEnabled && Color.shellValues["bar.accent-icons"] === "true"
      ? Color.pick("bar.icon-accent", Color.accent)
      : (bar ? bar.barForeground : Color.foreground))

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() {
      if (root.service) root.service.refreshCopyOnSelect()
    }
  }

  onPressed: function() {
    if (!root.ready || root.busy || !root.service) return
    root.service.setCopyOnSelect(!root.featureEnabled)
  }
}
