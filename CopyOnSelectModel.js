// Pure parsing helpers for the Hugin Copy on Select reconciliation interface.

function parseStatus(raw) {
  try {
    var value = JSON.parse(String(raw || ""))
    if (!value || typeof value !== "object" || Array.isArray(value)
        || value.schema !== 1 || value.state !== "ready"
        || typeof value.enabled !== "boolean") return null
    return value
  } catch (error) {
    return null
  }
}

function failure(message) {
  return {
    schema: 1,
    state: "error",
    enabled: false,
    message: String(message || "Copy on Select is unavailable.")
  }
}

function canToggle(status) {
  return !!status && status.state === "ready"
    && typeof status.enabled === "boolean"
}

if (typeof module !== "undefined") {
  module.exports = {
    parseStatus: parseStatus,
    failure: failure,
    canToggle: canToggle
  }
}
