// Pure status parsing and presentation helpers for Keychron Profiles.
// Kept independent of Qt so Node can verify the UI contract before loading QML.

var knownStates = [
  "checking", "ready", "disconnected", "unsupported", "permission_denied",
  "ambiguous", "timeout", "busy", "protocol_error", "selection_failed",
  "verification_failed", "io_error", "lock_error", "configuration_error"
]

function isObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}

function parseStatus(raw) {
  try {
    var value = JSON.parse(String(raw || ""))
    if (!isObject(value) || value.schema !== 1 || knownStates.indexOf(value.state) === -1)
      return null
    if (value.state === "ready") {
      if ([0, 1, 2].indexOf(value.activeIndex) === -1 || value.profileCount !== 3)
        return null
      if (typeof value.serial !== "string" || value.connection !== "wired")
        return null
    }
    return value
  } catch (error) {
    return null
  }
}

function profileName(index) {
  if (index === 0) return "Default"
  if (index === 1) return "Profile 2"
  if (index === 2) return "Gamepad"
  return "Unknown"
}

function icon(status) {
  if (status && status.state === "ready" && status.activeIndex === 2) return "󰊗"
  return "󰌌"
}

function canSwitch(status) {
  return !!status && status.state === "ready" && [0, 2].indexOf(status.activeIndex) !== -1
}

function stateLabel(status) {
  if (!status || status.state === "checking") return "Checking…"
  if (status.state === "ready") return profileName(status.activeIndex)
  if (status.state === "disconnected") return "Disconnected"
  if (status.state === "unsupported") return "Unsupported"
  if (status.state === "permission_denied") return "Permission denied"
  if (status.state === "ambiguous") return "Multiple keyboards"
  if (status.state === "timeout") return "Timed out"
  if (status.state === "busy") return "Busy"
  if (status.state === "configuration_error") return "Configuration error"
  return "Hardware error"
}

function tooltip(status) {
  if (!status) return "K10 HE · Checking hardware profile…"
  if (status.state === "ready")
    return "K10 HE · " + profileName(status.activeIndex) + " · Wired"
  return "K10 HE · " + stateLabel(status)
}

if (typeof module !== "undefined") {
  module.exports = {
    parseStatus: parseStatus,
    profileName: profileName,
    icon: icon,
    canSwitch: canSwitch,
    stateLabel: stateLabel,
    tooltip: tooltip
  }
}
